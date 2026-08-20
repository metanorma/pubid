# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Pubid::Ietf identifier hash round-trip" do
  cases = {
    "RFC 2119" => "pubid:ietf:rfc",
    "RFC 9110" => "pubid:ietf:rfc",
    "BCP 3" => "pubid:ietf:bcp",
    "STD 66" => "pubid:ietf:std",
    "FYI 1" => "pubid:ietf:fyi",
    "draft-giuliano-treedn-02" => "pubid:ietf:internet-draft",
    "draft-giuliano-treedn" => "pubid:ietf:internet-draft",
    "draft-adams-cast-256" => "pubid:ietf:internet-draft",
    "draft-ietf-pilc-2.5g3g-12" => "pubid:ietf:internet-draft",
    "draft-chapin-clnp-ISO8473-00" => "pubid:ietf:internet-draft",
  }

  cases.each do |ref, type|
    describe ref do
      let(:identifier) { Pubid::Ietf::Identifier.parse(ref) }
      let(:hash) { identifier.to_hash }

      it "serializes to a non-empty hash" do
        expect(hash).not_to be_empty
      end

      it "carries the #{type} _type" do
        expect(hash["_type"]).to eq(type)
      end

      it "rebuilds an equal identifier from its hash" do
        rebuilt = Pubid::Ietf::Identifier.from_hash(hash)
        expect(rebuilt.to_s).to eq(identifier.to_s)
      end

      it "is idempotent under from_hash(x.to_hash).to_hash" do
        rebuilt = Pubid::Ietf::Identifier.from_hash(hash)
        expect(rebuilt.to_hash).to eq(hash)
      end
    end
  end

  # The whole IETF vocabulary is three keys. Anything else is redundancy the
  # index would carry on every one of its ~176,862 rows.
  describe "the serialized vocabulary" do
    it "never emits series — _type already encodes it" do
      %w[BCP\ 3 STD\ 66 FYI\ 1].each do |ref|
        expect(Pubid::Ietf::Identifier.parse(ref).to_hash)
          .not_to have_key("series")
      end
    end

    it "still exposes series as a derived reader, before and after from_hash" do
      { "BCP 3" => "BCP", "STD 66" => "STD", "FYI 1" => "FYI" }
        .each do |ref, series|
        parsed = Pubid::Ietf::Identifier.parse(ref)
        expect(parsed.series).to eq(series)
        expect(Pubid::Ietf::Identifier.from_hash(parsed.to_hash).series)
          .to eq(series)
      end
    end

    it "never emits name — the draft slug lives in number" do
      parsed = Pubid::Ietf::Identifier.parse("draft-giuliano-treedn-02")
      expect(parsed.to_hash).not_to have_key("name")
      expect(parsed.to_hash["number"]).to eq("draft-giuliano-treedn")
    end

    it "drops version for an unversioned draft" do
      expect(Pubid::Ietf::Identifier.parse("draft-giuliano-treedn").to_hash)
        .not_to have_key("version")
    end

    it "gives a sub-series id the same key shape as an RFC" do
      expect(Pubid::Ietf::Identifier.parse("STD 66").to_hash.keys)
        .to eq(Pubid::Ietf::Identifier.parse("RFC 2119").to_hash.keys)
    end
  end
end
