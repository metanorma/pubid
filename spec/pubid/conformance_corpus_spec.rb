# frozen_string_literal: true

require "spec_helper"
require "yaml"

# Executes the neutral corpus type files (conformance/{flavor}/{type}.yml)
# against the Ruby reference implementation. Debt (_unparsed.yml) and
# negative (_negative.yml) files are covered by rake conformance:run.
RSpec.describe "conformance corpus" do
  flavors = Dir[File.expand_path("../../conformance/*", __dir__)]
    .select { |path| File.directory?(path) }
    .map { |path| File.basename(path) }

  flavors.each do |flavor|
    it "passes every #{flavor} case", :aggregate_failures do
      Pubid.eager_load_flavors!
      flavor_module = Pubid::Registry.get(flavor)
      expect(flavor_module).not_to be_nil, "unknown flavor #{flavor}"

      type_files = Dir[File.expand_path("../../conformance/#{flavor}/*.yml",
                                        __dir__)]
        .reject { |path| File.basename(path).start_with?("_") }
      expect(type_files).not_to be_empty

      type_files.each do |path|
        YAML.safe_load_file(path).each do |test_case|
          next if test_case["identifier"].nil? # quarantined reference-bug debt

          label = "#{flavor}/#{test_case.fetch('id')}"
          identifier = flavor_module.parse(test_case.fetch("input"))

          tree = Pubid::Conformance.component_tree(identifier.to_hash)
          expect(tree).to eq(test_case.fetch("identifier")),
                          "#{label} component tree"
          representations = test_case.fetch("representations")
          expect(identifier.to_s)
            .to eq(representations.fetch("human")), "#{label} human"
          if representations["urn"]
            expect(identifier.to_urn).to eq(representations["urn"]),
                                         "#{label} urn"
          end
          next unless test_case["roundtrip"]

          hash = identifier.to_hash
          expect(flavor_module::Identifier.from_hash(hash).to_hash)
            .to eq(hash), "#{label} from_hash round-trip"
        end
      end
    end
  end
end
