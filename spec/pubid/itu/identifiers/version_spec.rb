# frozen_string_literal: true

require "spec_helper"

# "(V##)" version marker — a real ITU-T rec_name suffix ("ITU-T H.264 (V14)
# (08/2021)"). Always sits between the code and the publication date.
RSpec.describe "ITU (V##) version" do
  def parse(str)
    Pubid::Itu.parse(str)
  end

  describe "ITU-T H.264 (V14) (08/2021)" do
    subject { "ITU-T H.264 (V14) (08/2021)" }

    let(:parsed) { parse(subject) }

    it "parses as a Recommendation" do
      expect(parsed).to be_a(Pubid::Itu::Identifiers::Recommendation)
    end

    it "parses the version" do
      expect(parsed.version).to eq("14")
    end

    it "keeps the publication date" do
      expect(parsed.date.month).to eq("08")
      expect(parsed.date.year).to eq("2021")
    end

    it "keeps the document number" do
      expect(parsed.code.number).to eq("264")
      expect(parsed.root.number.to_s).to eq("264")
    end

    it "round-trips" do
      expect(parsed.to_s).to eq(subject)
    end

    it "serializes the version" do
      expect(parsed.to_hash["version"]).to eq("14")
    end

    it "round-trips through to_hash/from_hash" do
      restored = Pubid::Itu::Identifier.from_hash(parsed.to_hash)
      expect(restored.to_s).to eq(subject)
      expect(restored.to_hash).to eq(parsed.to_hash)
    end
  end

  describe "other real forms" do
    {
      "ITU-T H.861.0 (V2) (01/2024)" => "2",
      "ITU-T T.816 (V1) (02/2023)" => "1",
      "ITU-T H.265 (V11) (01/2026)" => "11",
      "ITU-T F.746.10 (V3) (03/2023)" => "3",
    }.each do |str, version|
      it "parses and round-trips #{str}" do
        parsed = parse(str)
        expect(parsed.version).to eq(version)
        expect(parsed.to_s).to eq(str)
      end
    end
  end

  describe "version without a date" do
    it "parses" do
      parsed = parse("ITU-T H.264 (V14)")
      expect(parsed.version).to eq("14")
      expect(parsed.date).to be_nil
      expect(parsed.to_s).to eq("ITU-T H.264 (V14)")
    end
  end

  describe "identifiers without a version" do
    it "leaves version nil and does not serialize it" do
      parsed = parse("ITU-T H.264 (08/2021)")
      expect(parsed.version).to be_nil
      expect(parsed.to_hash).not_to have_key("version")
      expect(parsed.to_s).to eq("ITU-T H.264 (08/2021)")
    end

    it "still parses a bare recommendation" do
      expect(parse("ITU-T G.711").version).to be_nil
    end
  end

  describe "equality" do
    it "distinguishes versions" do
      expect(parse("ITU-T H.264 (V13) (08/2021)"))
        .not_to eq(parse("ITU-T H.264 (V14) (08/2021)"))
    end

    it "distinguishes a versioned identifier from a version-less one" do
      expect(parse("ITU-T H.264 (V14) (08/2021)"))
        .not_to eq(parse("ITU-T H.264 (08/2021)"))
    end

    it "is excluded by #exclude(:version)" do
      versioned = parse("ITU-T H.264 (V14) (08/2021)")
      expect(versioned.exclude(:version).version).to be_nil
      expect(
        versioned.matches?(parse("ITU-T H.264 (V13) (08/2021)"),
                           ignore: [:version]),
      ).to be true
    end

    # `version` is a separable trailing component like the date (the ETSI
    # `omits: %i[version date]` precedent), NOT part of the date, so excluding
    # the date alone does not wildcard it. A caller matching a bare reference
    # against versioned catalogue rows must ignore :version explicitly.
    it "is not wildcarded by a date-only exclusion" do
      bare = parse("ITU-T H.264")
      versioned = parse("ITU-T H.264 (V14) (08/2021)")

      expect(bare.matches?(versioned, ignore: %i[year month])).to be false
      expect(bare.matches?(versioned, ignore: %i[year month version]))
        .to be true
    end
  end

  describe "combined (joint) recommendation with a version" do
    subject { "ITU-T G.780/Y.1351 (V2) (2004)" }

    let(:parsed) { parse(subject) }

    it "parses as a CombinedIdentifier keeping the version" do
      expect(parsed).to be_a(Pubid::Itu::Identifiers::CombinedIdentifier)
      expect(parsed.version).to eq("2")
    end

    it "round-trips" do
      expect(parsed.to_s).to eq(subject)
    end

    it "distinguishes versions" do
      expect(parsed).not_to eq(parse("ITU-T G.780/Y.1351 (V3) (2004)"))
    end
  end

  # ITU emits four spellings of the same marker. All are accepted and
  # normalised to the canonical parenthesised form on render — the hash (the
  # relaton index gate) round-trips regardless, and this is why these strings
  # are NOT in the byte-exact pass fixture.
  describe "bare version spellings" do
    {
      "ITU-T Q.3403 v.1 (02/2016)" => ["1", "ITU-T Q.3403 (V1) (02/2016)"],
      "ITU-T Q.1902.1 v.2 (02/2016)" => ["2", "ITU-T Q.1902.1 (V2) (02/2016)"],
      "ITU-T H.764 V2 (11/2019)" => ["2", "ITU-T H.764 (V2) (11/2019)"],
      "ITU-T H.222.0 v10 (04/2025)" => ["10", "ITU-T H.222.0 (V10) (04/2025)"],
    }.each do |input, (version, canonical)|
      context input do
        let(:parsed) { parse(input) }

        it "captures the version" do
          expect(parsed.version).to eq(version)
        end

        it "renders the canonical parenthesised spelling" do
          expect(parsed.to_s).to eq(canonical)
        end

        it "round-trips through from_hash" do
          expect(Pubid::Itu::Identifier.from_hash(parsed.to_hash).to_hash)
            .to eq(parsed.to_hash)
        end

        it "equals the canonical spelling" do
          expect(parsed).to eq(parse(canonical))
        end
      end
    end

    it "still distinguishes versions across spellings" do
      expect(parse("ITU-T Q.3403 v.1")).not_to eq(parse("ITU-T Q.3403 v.2"))
    end

    it "does not claim a version-less identifier" do
      expect(parse("ITU-T H.264 (08/2021)").version).to be_nil
    end
  end
end
