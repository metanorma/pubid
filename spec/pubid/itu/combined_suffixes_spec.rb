# frozen_string_literal: true

require "spec_helper"

# Joint (combined) numbering is already modelled by CombinedIdentifier; these
# corpus records failed only because one or both halves carry a print-form
# suffix, for which the designation rule had no slot.
RSpec.describe "ITU combined designations with code suffixes" do
  def parse(str) = Pubid::Itu.parse(str)

  def round_trips?(str)
    parsed = parse(str)
    parsed.to_s == str &&
      Pubid::Itu::Identifier.from_hash(parsed.to_hash).to_hash == parsed.to_hash
  end

  describe "a qualifier on the primary designation only" do
    subject { "ITU-T D.301 R/F.66 (12/1972)" }

    let(:parsed) { parse(subject) }

    it "parses as a CombinedIdentifier" do
      expect(parsed).to be_a(Pubid::Itu::Identifiers::CombinedIdentifier)
    end

    it "keeps the qualifier on the primary code" do
      expect(parsed.code.number).to eq("301")
      expect(parsed.code.qualifier).to eq("R")
    end

    it "leaves the additional designation unqualified" do
      expect(parsed.combined.first.code.number).to eq("66")
      expect(parsed.combined.first.code.qualifier).to be_nil
    end

    it "round-trips" do
      expect(round_trips?(subject)).to be true
    end
  end

  describe "a qualifier on both halves" do
    subject { "ITU-T D.300 R/E.282 R (10/1976)" }

    let(:parsed) { parse(subject) }

    it "keeps a qualifier on each" do
      expect(parsed.code.qualifier).to eq("R")
      expect(parsed.combined.first.code.qualifier).to eq("R")
    end

    it "round-trips" do
      expect(round_trips?(subject)).to be true
    end

    it "is distinct from the singly-qualified form" do
      expect(parsed).not_to eq(parse("ITU-T D.300 R/E.282 (10/1976)"))
    end
  end

  describe "an edition word trailing the last designation" do
    {
      "ITU-T D.81/F.80 bis (12/1972)" => "bis",
      "ITU-T E.163/Q.11 bis (11/1988)" => "bis",
      "ITU-T E.165/Q.11 ter (11/1988)" => "ter",
      "ITU-T E.211/Q.11 quater (10/1984)" => "quater",
      "ITU-T E.211/Q.11 quarter (11/1980)" => "quarter",
      "ITU-T E.164/I.331/Q.11 bis (11/1988)" => "bis",
    }.each do |id, word|
      context id do
        let(:parsed) { parse(id) }

        it "stores the word on the designation it printed against" do
          expect(parsed.combined.last.code.series_suffix).to eq(word)
          expect(parsed.code.series_suffix).to be_nil
        end

        it "round-trips" do
          expect(round_trips?(id)).to be true
        end
      end
    end

    it "distinguishes the edition from the plain joint document" do
      expect(parse("ITU-T D.81/F.80 bis")).not_to eq(parse("ITU-T D.81/F.80"))
    end
  end

  describe "an ordinary joint designation is unchanged" do
    # Flag polarity check on the nested rows: no already-published combined
    # row may gain a key.
    it "keeps the existing two-key row shape" do
      hash = parse("ITU-T G.780/Y.1351 (2004)").to_hash

      expect(hash["combined"]).to eq([{ "series" => "Y", "number" => "1351" }])
    end

    [
      "ITU-T G.780/Y.1351 (2004)",
      "ITU-T G.780/Y.1351/Z.1362 (2004)",
    ].each do |id|
      it "still round-trips #{id}" do
        expect(round_trips?(id)).to be true
      end
    end
  end
end
