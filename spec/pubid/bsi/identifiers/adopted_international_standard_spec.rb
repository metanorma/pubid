# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Bsi::Identifiers::AdoptedInternationalStandard do
  subject { described_class }

  context "BS ISO adoption" do
    describe "BS ISO 8601:2019" do
      subject { "BS ISO 8601:2019" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as AdoptedInternationalStandard" do
        expect(parsed).to be_a(described_class)
      end

      it "has adopted_identifier" do
        expect(parsed.adopted_identifier).not_to be_nil
      end

      it "adopted_identifier is ISO object" do
        expect(parsed.adopted_identifier).to be_a(Pubid::Iso::Identifier)
      end

      it "delegates number to adopted identifier" do
        expect(parsed.number.to_s).to eq("8601")
      end

      it "delegates year to adopted identifier" do
        expect(parsed.date.year).to eq("2019")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    describe "BS ISO 9001:2015" do
      subject { "BS ISO 9001:2015" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as AdoptedInternationalStandard" do
        expect(parsed).to be_a(described_class)
      end

      it "delegates number" do
        expect(parsed.number.to_s).to eq("9001")
      end

      it "delegates date" do
        expect(parsed.date.year).to eq("2015")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    describe "BS ISO 1234" do
      subject { "BS ISO 1234" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as AdoptedInternationalStandard" do
        expect(parsed).to be_a(described_class)
      end

      it "has no date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  context "BS IEC adoption" do
    describe "BS IEC 62600:2020" do
      subject { "BS IEC 62600:2020" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as AdoptedInternationalStandard" do
        expect(parsed).to be_a(described_class)
      end

      it "has adopted_identifier" do
        expect(parsed.adopted_identifier).not_to be_nil
      end

      it "adopted_identifier is IEC object" do
        expect(parsed.adopted_identifier).to be_a(Pubid::Iec::Identifier)
      end

      it "delegates number to adopted identifier" do
        expect(parsed.number.to_s).to eq("62600")
      end

      it "delegates year to adopted identifier" do
        expect(parsed.date.year).to eq("2020")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    describe "BS IEC 60050-113:2011" do
      subject { "BS IEC 60050-113:2011" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as AdoptedInternationalStandard" do
        expect(parsed).to be_a(described_class)
      end

      it "delegates number" do
        expect(parsed.number.to_s).to eq("60050")
      end

      it "delegates part" do
        expect(parsed.part.to_s).to eq("113")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  context "BS ISO/IEC copublisher adoption" do
    describe "BS ISO/IEC 27001:2013" do
      subject { "BS ISO/IEC 27001:2013" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as AdoptedInternationalStandard" do
        expect(parsed).to be_a(described_class)
      end

      it "has adopted_identifier" do
        expect(parsed.adopted_identifier).not_to be_nil
      end

      it "adopted_identifier is ISO object" do
        expect(parsed.adopted_identifier).to be_a(Pubid::Iso::Identifier)
      end

      it "delegates number" do
        expect(parsed.number.to_s).to eq("27001")
      end

      it "delegates year" do
        expect(parsed.date.year).to eq("2013")
      end

      it "includes copublisher in output" do
        expect(parsed.to_s).to include("ISO/IEC")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    describe "BS ISO/IEC 15693-3:2019" do
      subject { "BS ISO/IEC 15693-3:2019" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as AdoptedInternationalStandard" do
        expect(parsed).to be_a(described_class)
      end

      it "delegates number" do
        expect(parsed.number.to_s).to eq("15693")
      end

      it "delegates part" do
        expect(parsed.part.to_s).to eq("3")
      end

      it "includes copublisher" do
        expect(parsed.to_s).to include("ISO/IEC")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  context "multi-digit numbers" do
    describe "BS ISO 10000:2022" do
      subject { "BS ISO 10000:2022" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as AdoptedInternationalStandard" do
        expect(parsed).to be_a(described_class)
      end

      it "delegates number" do
        expect(parsed.number.to_s).to eq("10000")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end
end
