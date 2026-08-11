# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Itu::Identifiers::CombinedIdentifier do
  describe "dual-series (from corpus)" do
    ["ITU-R SA.1745/RS.1745", "ITU-R RS.1745/SA.1745",
     "ITU-T G.780/Y.1351"].each do |id|
      context id do
        subject { id }

        let(:parsed) { Pubid::Itu.parse(subject) }

        it "parses as CombinedIdentifier" do
          expect(parsed).to be_a(described_class)
        end

        it "has one additional designation" do
          expect(parsed.combined.size).to eq(1)
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "round-trips through hash" do
          hash = parsed.to_hash
          expect(Pubid::Itu::Identifier.from_hash(hash).to_hash).to eq(hash)
        end
      end
    end

    it "keeps the primary designation on the base series/number" do
      parsed = Pubid::Itu.parse("ITU-T G.780/Y.1351")
      expect(parsed.series.series).to eq("G")
      expect(parsed.code.number).to eq("780")
      expect(parsed.combined.first.series.series).to eq("Y")
      expect(parsed.combined.first.code.number).to eq("1351")
    end
  end

  describe "triple-joint (synthetic)" do
    subject { "ITU-T G.780/Y.1351/Z.1362" }

    let(:parsed) { Pubid::Itu.parse(subject) }

    it "parses as CombinedIdentifier" do
      expect(parsed).to be_a(described_class)
    end

    it "has two additional designations" do
      expect(parsed.combined.map { |d| "#{d.series}.#{d.code}" })
        .to eq(["Y.1351", "Z.1362"])
    end

    it "round-trips" do
      expect(parsed.to_s).to eq(subject)
    end

    it "round-trips through hash" do
      hash = parsed.to_hash
      expect(Pubid::Itu::Identifier.from_hash(hash).to_hash).to eq(hash)
    end
  end

  describe "combined with date" do
    subject { "ITU-T G.780/Y.1351 (2004)" }

    let(:parsed) { Pubid::Itu.parse(subject) }

    it "round-trips" do
      expect(parsed.to_s).to eq(subject)
    end
  end

  describe "designations carrying a part / subseries" do
    # A combined designation can itself carry a "-part" or ".subseries"; both
    # must survive the flat serialization round-trip.
    ["ITU-T G.780/Y.1362-2", "ITU-T G.780/Y.1351.1",
     "ITU-T G.780-1/Y.1351"].each do |id|
      context id do
        subject { id }

        let(:parsed) { Pubid::Itu.parse(subject) }

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "round-trips through hash" do
          hash = parsed.to_hash
          expect(Pubid::Itu::Identifier.from_hash(hash).to_hash).to eq(hash)
        end
      end
    end
  end

  describe "as a supplement base" do
    # A supplement/amendment can wrap a combined recommendation; the nested
    # base must serialize (and round-trip) in its flat combined shape.
    subject { "ITU-T G.780/Y.1351 Amd. 1" }

    let(:parsed) { Pubid::Itu.parse(subject) }

    it "round-trips" do
      expect(parsed.to_s).to eq(subject)
    end

    it "nests a flat CombinedIdentifier base" do
      base = parsed.to_hash["base"]
      expect(base["_type"]).to eq("pubid:itu:combined-identifier")
      expect(base["combined"]).to eq([{ "series" => "Y", "number" => "1351" }])
    end

    it "round-trips through hash" do
      hash = parsed.to_hash
      expect(Pubid::Itu::Identifier.from_hash(hash).to_hash).to eq(hash)
    end
  end
end
