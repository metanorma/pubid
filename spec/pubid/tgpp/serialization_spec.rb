# frozen_string_literal: true

require "spec_helper"

# Round-trip invariant for index serialization: a parsed 3GPP identifier must
# survive `to_hash` → `from_hash` unchanged. This is the contract the Relaton
# index relies on (store `id.to_hash`, rebuild via `from_hash`).
#
# The gate is `==`, not `to_s`. A parsed identifier and a deserialized one can
# render identically and still compare unequal: the builder always passes a
# `parts` array, so a part-less identifier holds `[]`, while the serialized
# hash carries no `parts` key at all, so `from_hash` used to leave the
# attribute nil. `#matches?` is `exclude(*ignore) == other.exclude(*ignore)`,
# so that difference silently broke every part-less lookup against the relaton
# index. `parts` now defaults to `[]`, which both construction paths reach.
#
# The empty collection is omitted from the hash by lutaml's key_value
# serializer, independently of the default — so the `omits parts` examples
# below hold both before and after the fix, and the serialized shape of the
# published index is unchanged.
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

      # The real gate. The `to_s` comparison above is weaker: it passed even
      # while `parts` differed between the two construction paths.
      it "rebuilds an identifier that compares equal" do
        expect(Pubid::Tgpp::Identifier.from_hash(hash)).to eq(identifier)
      end

      it "round-trips the hash idempotently" do
        rebuilt = Pubid::Tgpp::Identifier.from_hash(hash)
        expect(rebuilt.to_hash).to eq(hash)
      end

      it "carries the same parts on both construction paths" do
        expect(Pubid::Tgpp::Identifier.from_hash(hash).parts)
          .to eq(identifier.parts)
      end
    end
  end

  # The `parts` attribute specifically: `[]` on both paths, and still absent
  # from the serialized hash.
  describe "empty parts" do
    part_less = [
      "TS 23.207:REL-4/4.0.0",          # release and version, no parts
      "TR 00.01U:UMTS/3.0.0",           # letter suffix, no parts
      "TS 29.215/2.0.0",                # release omitted, no parts
      "TS 23.207",                      # bare user reference
    ]

    part_less.each do |ref|
      context ref do
        let(:identifier) { Pubid::Tgpp::Identifier.parse(ref) }

        it "parses with an empty parts array" do
          expect(identifier.parts).to eq([])
        end

        it "deserializes with an empty parts array, never nil" do
          rebuilt = Pubid::Tgpp::Identifier.from_hash(identifier.to_hash)
          expect(rebuilt.parts).to eq([])
        end

        # The published index holds 88,464 rows. Emitting `parts: []` on the
        # ~81,000 part-less ones would inflate the artifact for nothing, and it
        # would be an index format change requiring a re-crawl.
        it "omits parts from the serialized hash" do
          expect(identifier.to_hash).not_to have_key("parts")
        end
      end
    end

    context "a parts-carrying identifier is unaffected" do
      let(:identifier) do
        Pubid::Tgpp::Identifier.parse("TS 29.198-04-1:REL-5/5.0.0")
      end

      it "serializes its parts" do
        expect(identifier.to_hash["parts"]).to eq(%w[04 1])
      end

      it "round-trips its parts" do
        rebuilt = Pubid::Tgpp::Identifier.from_hash(identifier.to_hash)
        expect(rebuilt.parts).to eq(%w[04 1])
      end
    end
  end
end
