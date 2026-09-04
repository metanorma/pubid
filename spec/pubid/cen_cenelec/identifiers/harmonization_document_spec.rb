require "spec_helper"

RSpec.describe Pubid::CenCenelec::Identifiers::HarmonizationDocument do
  subject { described_class }

  context "basic HD identifiers" do
    describe "HD 123:2020" do
      subject { "HD 123:2020" }

      let(:parsed) { Pubid::CenCenelec.parse(subject) }

      it "parses as HarmonizationDocument" do
        expect(parsed).to be_a(described_class)
      end

      it "parses publisher" do
        expect(parsed.publisher.body).to eq("HD")
      end

      it "parses number" do
        expect(parsed.number).to eq("123")
      end

      it "parses year" do
        expect(parsed.date.year).to eq("2020")
      end

      it "has correct type" do
        expect(parsed.type).to eq(:hd)
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    describe "HD 456" do
      subject { "HD 456" }

      let(:parsed) { Pubid::CenCenelec.parse(subject) }

      it "parses as HarmonizationDocument" do
        expect(parsed).to be_a(described_class)
      end

      it "parses undated identifier" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  context "HD with part number" do
    describe "HD 789-1:2019" do
      subject { "HD 789-1:2019" }

      let(:parsed) { Pubid::CenCenelec.parse(subject) }

      it "parses as HarmonizationDocument" do
        expect(parsed).to be_a(described_class)
      end

      it "parses number" do
        expect(parsed.number).to eq("789")
      end

      it "parses part" do
        expect(parsed.part).to eq("1")
      end

      it "parses year" do
        expect(parsed.date.year).to eq("2019")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    describe "HD 321-5:2021" do
      subject { "HD 321-5:2021" }

      let(:parsed) { Pubid::CenCenelec.parse(subject) }

      it "parses part" do
        expect(parsed.part).to eq("5")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  context "multi-digit numbers" do
    describe "HD 12345:2022" do
      subject { "HD 12345:2022" }

      let(:parsed) { Pubid::CenCenelec.parse(subject) }

      it "parses as HarmonizationDocument" do
        expect(parsed).to be_a(described_class)
      end

      it "parses large number" do
        expect(parsed.number).to eq("12345")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end
end
