require "spec_helper"

RSpec.describe Pubid::Iso::Identifiers::TechnologyTrendsAssessments do
  subject { described_class }


  # Test normal dated technology trends assessment
  context "parse normal dated technology trends assessment" do
    # ISO/TTA 1:1994
    describe "ISO/TTA 1:1994" do
      subject { "ISO/TTA 1:1994" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:tta:1" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses part" do
        expect(parsed.part&.value).to be_nil
      end

      it "parses date" do
        expect(parsed.date.year).to eq("1994")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("tta")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("TTA")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test normal undated technology trends assessment
  context "parse normal undated technology trends assessment" do
    # ISO/TTA 2
    describe "ISO/TTA 2" do
      subject { "ISO/TTA 2" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:tta:2" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses part" do
        expect(parsed.part&.value).to be_nil
      end

      it "parses date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("tta")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("TTA")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test multiple versions of same number
  context "parse multiple versions of same number" do
    # ISO/TTA 5:2006
    describe "ISO/TTA 5:2006" do
      subject { "ISO/TTA 5:2006" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:tta:5" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("5")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2006")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # ISO/TTA 5:2007 (updated version)
    describe "ISO/TTA 5:2007" do
      subject { "ISO/TTA 5:2007" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:tta:5" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("5")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2007")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end
end
