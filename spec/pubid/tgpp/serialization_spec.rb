# frozen_string_literal: true

require "spec_helper"

# Round-trip invariant for index serialization: a parsed 3GPP identifier must
# survive `to_hash` → `from_hash` unchanged. This is the contract the Relaton
# index relies on (store `id.to_hash`, rebuild via `from_hash`).
RSpec.describe "Pubid::Tgpp identifier hash round-trip" do
  refs = [
    "TS 23.207:REL-4/2.0.0",          # plain TS with REL- release
    "TR 26.905:REL-8/1.0.0",          # plain TR
    "TR 00.01U:UMTS/3.0.0",           # letter suffix + UMTS release
    "TS 02.06dcs:Ph1/2.0.0",          # 'dcs' suffix + phase release
    "TS 26.171-1:REL-8/8.0.0",        # single part
    "TS 29.198-04-1:REL-5/5.0.0",     # two-level zero-padded parts
    "TS 02.68:Release 2000/9.0.0",    # 'Release N' release form
    "TS 29.215/2.0.0",                # release omitted
    "TS 23.207:REL-4",                # version omitted
    "TS 23.207",                      # bare user reference
    "TR 00.01U",                      # bare, with a letter suffix
  ]

  refs.each do |ref|
    describe ref do
      let(:identifier) { Pubid::Tgpp::Identifier.parse(ref) }
      let(:hash) { identifier.to_hash }

      it "serializes to a non-empty hash" do
        expect(hash).not_to be_empty
      end

      it "carries the polymorphic _type tag" do
        expect(hash["_type"]).to start_with("pubid:3gpp:")
      end

      it "rebuilds an equal identifier from its hash" do
        rebuilt = Pubid::Tgpp::Identifier.from_hash(hash)
        expect(rebuilt.to_s).to eq(identifier.to_s)
      end

      it "round-trips the hash idempotently" do
        rebuilt = Pubid::Tgpp::Identifier.from_hash(hash)
        expect(rebuilt.to_hash).to eq(hash)
      end
    end
  end
end
