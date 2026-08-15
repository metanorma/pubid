# frozen_string_literal: true

require "spec_helper"

# Compact flat serialization for ITU (mirrors ISO/ETSI/JCGM/OIML): identity
# components collapse to top-level scalars — no nested `sector`/`series`/`code`/
# `date` sub-hashes — and the round-trip through from_hash is idempotent.
RSpec.describe "Pubid::Itu compact flat serialization" do
  # A representative id per subtype.
  REPRESENTATIVE_IDS = {
    "recommendation" => "ITU-R BO.600-1",
    "recommendation/no-series" => "ITU-R 20-200",
    "combined/dual" => "ITU-R SA.1745/RS.1745",
    "combined/triple" => "ITU-T G.780/Y.1351/Z.1362",
    "supplement" => "ITU-T E.156 Suppl. 2",
    "amendment" => "ITU-T G.989 Amd. 1",
    "corrigendum" => "ITU-T Z.100 (1999) Cor. 1 (10/2001)",
    "errata" => "ITU-T G.9701 (2014) Err. 1 (07/2016)",
    "annex" => "Annex to ITU OB No. 1000",
    "annex-of-recommendation" => "ITU-T A.23 Annex A (06/2014)",
    "annex-of-recommendation/corrigendum" =>
      "ITU-T G.729 Annex B (1996) Cor. 3 (03/2001)",
    "recommendation/version" => "ITU-T H.264 (V14) (08/2021)",
    "special-publication" => "ITU OB No. 1283 (01/2024)",
    "question/numeric" => "ITU-R 234-1/7:",
    "question/letter" => "ITU-R P.3/BL/7",
    "handbook" => "ITU-R 23.HDB",
    "report" => "Report ITU-R BT.2020-1 (2000)",
    "report/supplement" => "Report ITU-R BT.2020-1 Suppl. 1",
  }.freeze

  NESTED_KEYS = %w[sector series code combined_series combined_code].freeze

  REPRESENTATIVE_IDS.each do |label, id|
    describe "#{label} (#{id})" do
      let(:parsed) { Pubid::Itu.parse(id) }
      let(:hash) { parsed.to_hash }

      it "renders back to the source string" do
        expect(parsed.to_s).to eq(id)
      end

      it "round-trips through from_hash idempotently" do
        expect(Pubid::Itu::Identifier.from_hash(hash).to_hash).to eq(hash)
      end

      it "is flat — no nested identity sub-hashes" do
        NESTED_KEYS.each do |key|
          expect(hash[key]).not_to be_a(Hash),
                                   "expected #{key.inspect} not to be a nested Hash in #{hash.inspect}"
        end
        expect(hash).not_to have_key("code")
      end

      it "carries publisher only via default (never serialized)" do
        expect(hash).not_to have_key("publisher")
      end
    end
  end

  describe "exact shapes" do
    it "Recommendation ITU-R BO.600-1" do
      expect(Pubid::Itu.parse("ITU-R BO.600-1").to_hash).to eq(
        "_type" => "pubid:itu:recommendation",
        "sector" => "R",
        "series" => "BO",
        "number" => "600",
        "parts" => ["1"],
      )
    end

    it "Handbook ITU-R 23.HDB" do
      expect(Pubid::Itu.parse("ITU-R 23.HDB").to_hash).to eq(
        "_type" => "pubid:itu:handbook",
        "sector" => "R",
        "number" => "23",
      )
    end

    it "numeric Question ITU-R 234-1/7:" do
      expect(Pubid::Itu.parse("ITU-R 234-1/7:").to_hash).to eq(
        "_type" => "pubid:itu:question",
        "sector" => "R",
        "number" => "234",
        "parts" => ["1"],
        "study_group" => "7",
        "has_colon" => true,
      )
    end

    it "letter Question ITU-R P.3/BL/7" do
      expect(Pubid::Itu.parse("ITU-R P.3/BL/7").to_hash).to eq(
        "_type" => "pubid:itu:question",
        "sector" => "R",
        "series" => "P",
        "number" => "3",
        "study_group" => "7",
        "has_bl" => true,
      )
    end

    it "triple Combined ITU-T G.780/Y.1351/Z.1362" do
      expect(Pubid::Itu.parse("ITU-T G.780/Y.1351/Z.1362").to_hash).to eq(
        "_type" => "pubid:itu:combined-identifier",
        "sector" => "T",
        "series" => "G",
        "number" => "780",
        "combined" => [
          { "series" => "Y", "number" => "1351" },
          { "series" => "Z", "number" => "1362" },
        ],
      )
    end

    it "common-text twin serializes as a nested flat cross-flavor identifier" do
      id = "ITU-T H.222.0 (2021) | ISO/IEC 13818-1:2022"
      pid = Pubid::Itu.parse(id)
      hash = pid.to_hash

      expect(hash["common_text_twin"]).to include(
        "_type" => "pubid:iso:international-standard",
        "number" => "13818",
      )
      restored = Pubid::Itu::Identifier.from_hash(hash)
      expect(restored.to_s).to eq(id)
      expect(restored.to_hash).to eq(hash)
      expect(restored.common_text_twin)
        .to be_a(Pubid::Iso::Identifiers::InternationalStandard)
    end

    it "Recommendation with a version ITU-T H.264 (V14) (08/2021)" do
      expect(Pubid::Itu.parse("ITU-T H.264 (V14) (08/2021)").to_hash).to eq(
        "_type" => "pubid:itu:recommendation",
        "sector" => "T",
        "series" => "H",
        "number" => "264",
        "version" => "14",
        "year" => "2021",
        "month" => "08",
      )
    end

    it "AnnexOfRecommendation keeps only its label, date and a flat base" do
      hash = Pubid::Itu.parse("ITU-T A.23 Annex A (06/2014)").to_hash
      expect(hash).to eq(
        "_type" => "pubid:itu:annex-of-recommendation",
        "number" => "A",
        "year" => "2014",
        "month" => "06",
        "base" => {
          "_type" => "pubid:itu:recommendation",
          "sector" => "T",
          "series" => "A",
          "number" => "23",
        },
      )
    end

    it "Supplement suppresses redundant sector/series but keeps a flat base" do
      hash = Pubid::Itu.parse("ITU-T E.156 Suppl. 2").to_hash
      expect(hash).to eq(
        "_type" => "pubid:itu:supplement",
        "number" => "2",
        "base" => {
          "_type" => "pubid:itu:recommendation",
          "sector" => "T",
          "series" => "E",
          "number" => "156",
        },
      )
    end
  end
end
