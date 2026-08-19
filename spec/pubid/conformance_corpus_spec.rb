# frozen_string_literal: true

require "spec_helper"
require "yaml"

# Executes the neutral corpus from the pubid-tests repository
# (tests/{flavor}/*.yaml) against the Ruby reference implementation.
# Debt (_debt.yaml) and negatives (_negative.yaml) are covered by
# rake conformance:run.
RSpec.describe "pubid-tests corpus" do
  corpus_repo = ENV.fetch("PUBID_TESTS_PATH",
    File.expand_path("../../../pubid-tests", __dir__))
  unless File.directory?(File.join(corpus_repo, "tests"))
    raise "pubid-tests corpus not found at #{corpus_repo}: " \
          "clone pubid/pubid-tests as a sibling or set PUBID_TESTS_PATH"
  end
  tests_repo = ENV.fetch("PUBID_TESTS_PATH",
                         File.expand_path("../../../pubid-tests", __dir__))
  flavors = Dir[File.join(tests_repo, "tests", "*")]
             .select { |path| File.directory?(path) }
             .map { |path| File.basename(path) }

  flavors = flavors.reject do |flavor|
    status = File.join(tests_repo, "tests", flavor, "_status.yaml")
    next true if File.exist?(status) && !YAML.safe_load_file(status)["clean"]

    type = Dir[File.join(tests_repo, "tests", flavor, "*.yaml")]
           .reject { |path| File.basename(path).start_with?("_") }
    type.empty? # flavors with only fail-fixtures have no cases to gate
  end

  flavors.each do |flavor|
    it "passes every #{flavor} case", :aggregate_failures do
      Pubid.eager_load_flavors!
      registry_key = { "tgpp" => "3gpp" }.fetch(flavor, flavor)
      flavor_module = Pubid::Registry.get(registry_key)
      expect(flavor_module).not_to be_nil, "unknown flavor #{flavor}"

      type_files = Dir[File.join(tests_repo, "tests", flavor, "*.yaml")]
                   .reject { |path| File.basename(path).start_with?("_") }
      expect(type_files).not_to be_empty

      type_files.each do |path|
        YAML.safe_load_file(path).each do |test_case|
          next if test_case["identifier"].nil? # quarantined reference-bug debt

          label = "#{flavor}/#{test_case.fetch('id')}"
          human = test_case.dig("representations", "human")
          identifier = flavor_module.parse(human)

          actual = Pubid::Conformance.plainify(identifier.to_hash)
          expect(actual).to eq(test_case.fetch("identifier")),
                             "#{label} canonical hash"
          representations = test_case.fetch("representations")
          expect(identifier.to_s).to eq(human), "#{label} human"
          if representations["urn"]
            expect(identifier.to_urn).to eq(representations["urn"]),
                                         "#{label} urn"
          end
          next unless test_case["roundtrip"] == false

          hash = identifier.to_hash
          expect(flavor_module::Identifier.from_hash(hash).to_hash)
            .to eq(hash), "#{label} round-trip exception recorded"
        end
      end
    end
  end
end
