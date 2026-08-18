# frozen_string_literal: true

require "spec_helper"
require "yaml"

# Executes the shared conformance corpus (conformance/**/*.yml) against the
# Ruby reference implementation. Gates are defined in docs/CONFORMANCE.md.
# Seed harness for TODO.restructure/11; the parameterized per-case executor
# arrives with the TODO.restructure/10 generator.
RSpec.describe "conformance corpus" do
  it "passes every recorded case", :aggregate_failures do
    Pubid.eager_load_flavors!
    files = Dir[File.expand_path("../../conformance/**/*.yml", __dir__)]
    expect(files).not_to be_empty

    files.each do |path|
      flavor = File.basename(File.dirname(path))
      flavor_module = Pubid::Registry.get(flavor)
      expect(flavor_module).not_to be_nil, "unknown flavor #{flavor}"

      YAML.safe_load_file(path).each do |test_case|
        label = "#{flavor}/#{test_case.fetch('id')}"
        expectation = test_case.fetch("expect")
        identifier = flavor_module.parse(test_case.fetch("input"))

        expect(identifier.to_s).to eq(expectation.fetch("to_s")), 
                                   "#{label} to_s"
        if expectation["class_name"]
          expect(identifier.class.name)
            .to eq(expectation["class_name"]), "#{label} class"
        end
        if expectation["to_hash"]
          expect(identifier.to_hash)
            .to eq(expectation["to_hash"]), "#{label} to_hash"
        end
        if expectation["to_urn"]
          expect(identifier.to_urn)
            .to eq(expectation["to_urn"]), "#{label} to_urn"
        end
        next unless expectation["roundtrip"]

        hash = identifier.to_hash
        expect(flavor_module::Identifier.from_hash(hash).to_hash)
          .to eq(hash), "#{label} from_hash round-trip"
      end
    end
  end
end
