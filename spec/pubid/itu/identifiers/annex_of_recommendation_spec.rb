# frozen_string_literal: true

require "spec_helper"

# A labelled annex of a Recommendation — "ITU-T A.23 Annex A (06/2014)". The
# annex is a document in its own right, published (and dated) separately from
# the Recommendation it annexes. Distinct from Identifiers::Annex, which models
# the label-less "Annex to ITU OB No. 1000" form.
RSpec.describe Pubid::Itu::Identifiers::AnnexOfRecommendation do
  def parse(str)
    Pubid::Itu.parse(str)
  end

  describe "ITU-T A.23 Annex A (06/2014)" do
    subject { "ITU-T A.23 Annex A (06/2014)" }

    let(:parsed) { parse(subject) }

    it "parses as an AnnexOfRecommendation" do
      expect(parsed).to be_a(described_class)
    end

    it "parses the annex label" do
      expect(parsed.number).to eq("A")
    end

    it "parses its own date" do
      expect(parsed.date.month).to eq("06")
      expect(parsed.date.year).to eq("2014")
    end

    it "keeps the annexed Recommendation as its base" do
      expect(parsed.base).to be_a(Pubid::Itu::Identifiers::Recommendation)
      expect(parsed.base.code.number).to eq("23")
      expect(parsed.base.series.series).to eq("A")
      expect(parsed.base.date).to be_nil
    end

    it "keys the index on the annexed document number" do
      expect(parsed.root.number.to_s).to eq("23")
    end

    it "round-trips" do
      expect(parsed.to_s).to eq(subject)
    end

    it "round-trips through to_hash/from_hash" do
      restored = Pubid::Itu::Identifier.from_hash(parsed.to_hash)
      expect(restored).to be_a(described_class)
      expect(restored.to_s).to eq(subject)
      expect(restored.to_hash).to eq(parsed.to_hash)
    end

    it "generates a URN carrying the annex label and its own date" do
      expect(parsed.to_urn).to eq("urn:itu:t:A.23:annex:a:06/2014")
    end

    it "keys a distinct MR slug per annex and edition" do
      expect(parsed.to_mr_string).to eq("itu.t.a-23_annex.a.2014")
      expect(parse("ITU-T A.23 Annex B (06/2014)").to_mr_string)
        .not_to eq(parsed.to_mr_string)
      expect(parse("ITU-T A.23 Annex A (03/2010)").to_mr_string)
        .not_to eq(parsed.to_mr_string)
    end
  end

  describe "label shapes" do
    {
      "ITU-T A.23 Annex A" => "A",
      "ITU-T Z.100 Annex F3 (10/2019)" => "F3",
      "ITU-T G.729 Annex C+ (02/2000)" => "C+",
      "ITU-T G.722.2 Annex B (07/2003)" => "B",
      "ITU-T H.323 Annex M2 (03/2004)" => "M2",
    }.each do |str, label|
      it "parses and round-trips #{str}" do
        parsed = parse(str)
        expect(parsed).to be_a(described_class)
        expect(parsed.number).to eq(label)
        expect(parsed.to_s).to eq(str)
      end
    end
  end

  # CombinedIdentifier renders via `render_base`, which this class composes —
  # rendering it via `to_s` instead silently dropped the "/Y.1351" half and
  # gave two distinct documents the same printed identifier.
  describe "annex of a joint (combined) recommendation" do
    it "keeps every co-designation" do
      expect(parse("ITU-T G.780/Y.1351 Annex A").to_s)
        .to eq("ITU-T G.780/Y.1351 Annex A")
    end

    it "stays distinct from an annex of a different joint pairing" do
      expect(parse("ITU-T G.780/Y.1351 Annex A").to_s)
        .not_to eq(parse("ITU-T G.780/Z.1362 Annex A").to_s)
    end
  end

  describe "annex without a date" do
    it "leaves the date nil" do
      parsed = parse("ITU-T A.23 Annex A")
      expect(parsed.date).to be_nil
      expect(parsed.to_s).to eq("ITU-T A.23 Annex A")
    end
  end

  # The base's own date must survive alongside the annex's — the parse tree
  # nests the base under :base precisely so the two dates cannot collide.
  describe "base date before the annex" do
    subject { "ITU-T X.692 (2002) Annex E (03/2002)" }

    let(:parsed) { parse(subject) }

    it "keeps the base's date" do
      expect(parsed.base.date.year).to eq("2002")
      expect(parsed.base.date.month).to be_nil
    end

    it "keeps the annex's own date" do
      expect(parsed.date.month).to eq("03")
      expect(parsed.date.year).to eq("2002")
    end

    it "round-trips" do
      expect(parsed.to_s).to eq(subject)
    end
  end

  describe "supplements of an annex" do
    it "parses a corrigendum of an annex" do
      parsed = parse("ITU-T G.729 Annex B (1996) Cor. 3 (03/2001)")

      expect(parsed).to be_a(Pubid::Itu::Identifiers::Corrigendum)
      expect(parsed.number).to eq("3")
      expect(parsed.base).to be_a(described_class)
      expect(parsed.base.number).to eq("B")
      expect(parsed.base.base.code.number).to eq("729")
      expect(parsed.root.number.to_s).to eq("729")
      expect(parsed.to_s).to eq("ITU-T G.729 Annex B (1996) Cor. 3 (03/2001)")
    end

    it "parses an errata of an annex" do
      parsed = parse("ITU-T G.722.2 Annex B (2002) Err. 1 (07/2003)")

      expect(parsed).to be_a(Pubid::Itu::Identifiers::Errata)
      expect(parsed.base).to be_a(described_class)
      expect(parsed.to_s).to eq("ITU-T G.722.2 Annex B (2002) Err. 1 (07/2003)")
    end

    it "parses an amendment of an annex" do
      parsed = parse("ITU-T J.112 Annex B (2001) Amd. 1 (02/2002)")

      expect(parsed).to be_a(Pubid::Itu::Identifiers::Amendment)
      expect(parsed.number).to eq("1")
      expect(parsed.base).to be_a(described_class)
      expect(parsed.base.number).to eq("B")
    end

    it "round-trips a corrigendum of an annex through to_hash/from_hash" do
      parsed = parse("ITU-T G.729 Annex B (1996) Cor. 3 (03/2001)")
      restored = Pubid::Itu::Identifier.from_hash(parsed.to_hash)

      expect(restored.to_s).to eq(parsed.to_s)
      expect(restored.to_hash).to eq(parsed.to_hash)
    end
  end

  describe "equality" do
    it "distinguishes annex labels" do
      expect(parse("ITU-T A.23 Annex A")).not_to eq(parse("ITU-T A.23 Annex B"))
    end

    it "distinguishes the annexed document" do
      expect(parse("ITU-T A.23 Annex A")).not_to eq(parse("ITU-T A.24 Annex A"))
    end

    it "matches the same annex of another edition when the date is ignored" do
      expect(
        parse("ITU-T A.23 Annex A")
          .matches?(parse("ITU-T A.23 Annex A (06/2014)"),
                    ignore: %i[year month]),
      ).to be true
    end

    it "is not equal to the annexed Recommendation itself" do
      expect(parse("ITU-T A.23 Annex A")).not_to eq(parse("ITU-T A.23"))
    end
  end

  # PEG ordered choice: the new alternative must not shadow anything that used
  # to parse, and must itself be shadowed by supplement_identifier.
  describe "grammar ordering is unchanged for existing forms" do
    {
      "ITU-T E.156 Suppl. 2" => Pubid::Itu::Identifiers::Supplement,
      "ITU-T H Suppl. 1" => Pubid::Itu::Identifiers::Supplement,
      "Annex to ITU OB No. 1283 (01/2024)" => Pubid::Itu::Identifiers::Annex,
      "ITU-R P.3/BL/7" => Pubid::Itu::Identifiers::Question,
      "ITU-R 23.HDB" => Pubid::Itu::Identifiers::Handbook,
      "ITU-T G.780/Y.1351" => Pubid::Itu::Identifiers::CombinedIdentifier,
      "ITU-T BO.1073-1" => Pubid::Itu::Identifiers::Recommendation,
      "ITU OB No. 1000" => Pubid::Itu::Identifiers::SpecialPublication,
    }.each do |str, klass|
      it "still parses #{str} as #{klass}" do
        expect(parse(str)).to be_a(klass)
      end
    end

    it "still parses the common-text form" do
      parsed = parse("ITU-T H.222.0 (2021) | ISO/IEC 13818-1:2022")
      expect(parsed.common_text_twin).not_to be_nil
    end
  end
end
