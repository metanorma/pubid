# frozen_string_literal: true

require "spec_helper"

# ITU-R Reports are a distinct publication series that numbers independently of
# Recommendations, so the same series/number/edition is TWO real documents:
#
#   Report ITU-R BT.2020-1 (2000)          "Objective quality assessment ..."
#   Recommendation ITU-R BT.2020-1 (06/2014) "Parameter values for UHDTV ..."
#
# ITU resolves the collision with the leading word, and so must the identifier.
RSpec.describe Pubid::Itu::Identifiers::Report do
  def parse(str) = Pubid::Itu.parse(str)

  describe "parsing" do
    it "parses ITU's own citation form" do
      id = parse("Report ITU-R BT.2020-1")

      expect(id).to be_a(described_class)
      expect(id.sector.to_s).to eq("R")
      expect(id.series.to_s).to eq("BT")
      expect(id.code.number.to_s).to eq("2020")
      expect(id.code.parts.map(&:to_s)).to eq(["1"])
    end

    it "parses the infix spelling used by downstream bibliographies" do
      expect(parse("ITU-R Report BT.2020-1"))
        .to eq(parse("Report ITU-R BT.2020-1"))
    end

    it "parses a dated report" do
      id = parse("Report ITU-R BT.2020-1 (2000)")

      expect(id.date.year.to_s).to eq("2000")
      expect(id.date.month).to be_nil
    end

    it "parses a month-dated report" do
      id = parse("Report ITU-R M.2083-0 (09/2015)")

      expect(id.date.month.to_s).to eq("09")
      expect(id.date.year.to_s).to eq("2015")
    end

    it "parses an edition-less report" do
      id = parse("Report ITU-R BT.2020")

      expect(id.code.number.to_s).to eq("2020")
      expect(id.code.parts).to be_empty
    end

    it "parses a series-less report" do
      id = parse("Report ITU-R 2205")

      expect(id.series).to be_nil
      expect(id.code.number.to_s).to eq("2205")
    end

    it "parses a language-suffixed report" do
      expect(parse("Report ITU-R BT.2020-1-F").language).to eq("F")
    end

    it "refuses an Operational Bulletin as a report" do
      expect { parse("Report ITU-T OB.1") }.to raise_error(StandardError)
    end
  end

  describe "rendering" do
    {
      "Report ITU-R BT.2020-1" => "Report ITU-R BT.2020-1",
      "Report ITU-R BT.2020-1 (2000)" => "Report ITU-R BT.2020-1 (2000)",
      "Report ITU-R M.2083-0 (09/2015)" => "Report ITU-R M.2083-0 (09/2015)",
      "Report ITU-R 2205" => "Report ITU-R 2205",
      # The infix spelling normalizes to ITU's own leading form.
      "ITU-R Report BT.2020-1" => "Report ITU-R BT.2020-1",
    }.each do |input, expected|
      it "renders #{input.inspect} as #{expected.inspect}" do
        expect(parse(input).to_s).to eq(expected)
      end
    end
  end

  describe "distinctness from a Recommendation of the same number" do
    let(:report) { parse("Report ITU-R BT.2020-1") }
    let(:recommendation) { parse("ITU-R BT.2020-1") }

    it "is a different type" do
      expect(recommendation).to be_a(Pubid::Itu::Identifiers::Recommendation)
      expect(report).to be_a(described_class)
    end

    it "compares unequal in both directions" do
      expect(report).not_to eq(recommendation)
      expect(recommendation).not_to eq(report)
    end

    it "cannot be resolved to one another by #matches?" do
      expect(report.matches?(recommendation, ignore: %i[year])).to be false
      expect(recommendation.matches?(report, ignore: %i[year])).to be false
    end

    it "renders, URNs and slugs differently" do
      expect(report.to_s).not_to eq(recommendation.to_s)
      expect(report.to_urn).not_to eq(recommendation.to_urn)
      expect(report.to_mr_string).not_to eq(recommendation.to_mr_string)
    end
  end

  describe "serialization" do
    let(:report) { parse("Report ITU-R BT.2020-1 (2000)") }
    let(:hash) { report.to_hash }

    it "carries its own polymorphic type" do
      expect(hash["_type"]).to eq("pubid:itu:report")
    end

    it "is flat, like every other ITU leaf" do
      expect(hash["number"]).to eq("2020")
      expect(hash["series"]).to eq("BT")
      expect(hash["sector"]).to eq("R")
      expect(hash["year"]).to eq("2000")
    end

    it "round-trips through from_hash idempotently" do
      restored = Pubid::Itu::Identifier.from_hash(hash)

      expect(restored).to be_a(described_class)
      expect(restored.to_hash).to eq(hash)
      expect(restored.to_s).to eq(report.to_s)
      expect(restored).to eq(report)
    end

    it "exposes a non-empty root.number for Relaton::Index" do
      expect(report.root.number.to_s).to eq("2020")
    end
  end

  describe "URN" do
    it "marks the report in the URN" do
      expect(parse("Report ITU-R BT.2020-1 (2000)").to_urn)
        .to eq("urn:itu:r:report:BT.2020-1:2000")
    end

    it "parses back from its URN" do
      expect(Pubid::Itu::UrnParser.parse("urn:itu:r:report:BT.2020-1"))
        .to eq(parse("Report ITU-R BT.2020-1"))
    end
  end

  describe "wrappers" do
    it "supports a supplement of a report" do
      id = parse("Report ITU-R BT.2020-1 Suppl. 1")

      expect(id).to be_a(Pubid::Itu::Identifiers::Supplement)
      expect(id.base).to be_a(described_class)
      expect(id.to_s).to eq("Report ITU-R BT.2020-1 Suppl. 1")
      expect(id.root.number.to_s).to eq("2020")
      expect(Pubid::Itu::Identifier.from_hash(id.to_hash).to_hash)
        .to eq(id.to_hash)
    end

    it "supports an annex of a report" do
      id = parse("Report ITU-R BT.2020-1 Annex A")

      expect(id).to be_a(Pubid::Itu::Identifiers::AnnexOfRecommendation)
      expect(id.base).to be_a(described_class)
      expect(id.to_s).to eq("Report ITU-R BT.2020-1 Annex A")
      expect(id.root.number.to_s).to eq("2020")
      expect(Pubid::Itu::Identifier.from_hash(id.to_hash).to_hash)
        .to eq(id.to_hash)
    end
  end

  # The published index holds 20,728 rows keyed on these hashes; adding the
  # Report type must not perturb a single one of them.
  describe "backwards compatibility" do
    it "leaves a bare identifier a Recommendation" do
      id = parse("ITU-R BT.2020-1")

      expect(id).to be_a(Pubid::Itu::Identifiers::Recommendation)
      expect(id.to_hash).to eq(
        "_type" => "pubid:itu:recommendation",
        "sector" => "R",
        "series" => "BT",
        "number" => "2020",
        "parts" => ["1"],
      )
      expect(id.to_s).to eq("ITU-R BT.2020-1")
      expect(id.to_urn).to eq("urn:itu:r:BT.2020-1")
    end

    it "leaves the 'Recommendation' long-form prefix alone" do
      expect(parse("Recommendation ITU-R BT.2020-1"))
        .to eq(parse("ITU-R BT.2020-1"))
    end
  end
end
