# frozen_string_literal: true

require "spec_helper"

# Round-trip invariant for index serialization: a parsed OASIS identifier must
# survive `to_hash` -> `from_hash` unchanged. This is the contract the Relaton
# index relies on (store `id.to_hash`, rebuild via `from_hash`).
RSpec.describe "Pubid::Oasis identifier hash round-trip" do
  refs = [
    "OASIS amqp-core",                            # bare spec
    "OASIS WSDM-v1.1",                            # spec + version
    "OASIS amqp-core-overview-v1.0-Pt0",          # spec + version + part
    "OASIS OSLC-CoreShapes-3.0-PS01-Pt8",         # spec+version+stage+part
    "OASIS AkomaNtosoCore-v1.0-Pt2-Specifications", # + trailing label
    "OASIS OSLC-AM-3.0-Part1-PS01",               # part-before-stage order
    "OASIS CMIS-v1.1-Errata01",                   # errata stage
    "OASIS CTAS-v3.0]-PS01",                      # malformed, verbatim original
  ]

  refs.each do |ref|
    describe ref do
      let(:identifier) { Pubid::Oasis::Identifier.parse(ref) }
      let(:hash) { identifier.to_hash }

      it "serializes to a non-empty hash" do
        expect(hash).not_to be_empty
      end

      it "carries the polymorphic _type" do
        expect(hash["_type"]).to eq("pubid:oasis:standard")
      end

      # The specification name is serialized as `number`, never `spec`: it is
      # the key relaton-index sorts and binary-searches on.
      it "serializes the specification name as `number`" do
        expect(hash).not_to have_key("spec")
        expect(hash["number"]).to eq(identifier.number)
        expect(hash["number"]).not_to be_empty
      end

      it "rebuilds an equal identifier from its hash" do
        rebuilt = Pubid::Oasis::Identifier.from_hash(hash)
        expect(rebuilt.to_s).to eq(identifier.to_s)
      end

      it "round-trips the hash idempotently" do
        rebuilt = Pubid::Oasis::Identifier.from_hash(hash)
        expect(rebuilt.to_hash).to eq(hash)
      end
    end
  end
end
