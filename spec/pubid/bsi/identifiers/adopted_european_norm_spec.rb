# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Bsi::Identifiers::AdoptedEuropeanNorm do
  subject { described_class }

  context "single-level EN adoption" do
    describe "BS EN 10077-1:2006" do
      subject { "BS EN 10077-1:2006" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as AdoptedEuropeanNorm" do
        expect(parsed).to be_a(described_class)
      end

      it "has adopted_identifier" do
        expect(parsed.adopted_identifier).not_to be_nil
      end

      it "adopted_identifier is CEN object" do
        expect(parsed.adopted_identifier.class.name).to start_with("Pubid::CenCenelec::")
      end

      it "delegates number to adopted identifier" do
        expect(parsed.number).to eq("10077")
      end

      it "delegates part to adopted identifier" do
        expect(parsed.part).to eq("1")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    describe "BS EN 1234:2020" do
      subject { "BS EN 1234:2020" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as AdoptedEuropeanNorm" do
        expect(parsed).to be_a(described_class)
      end

      it "delegates number" do
        expect(parsed.number).to eq("1234")
      end

      it "delegates date" do
        expect(parsed.date.year).to eq("2020")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    describe "BS EN 5678" do
      subject { "BS EN 5678" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as AdoptedEuropeanNorm" do
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

  context "EN with parts and subparts" do
    describe "BS EN 1991-1-1:2002" do
      subject { "BS EN 1991-1-1:2002" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as AdoptedEuropeanNorm" do
        expect(parsed).to be_a(described_class)
      end

      it "delegates number" do
        expect(parsed.number).to eq("1991")
      end

      it "delegates part (includes subpart as combined value)" do
        # CEN parser captures "1-1" as combined part value
        expect(parsed.part).to eq("1-1")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  context "EN/CLC copublisher" do
    describe "BS EN/CLC TS 50131-1:2006" do
      subject { "BS EN/CLC TS 50131-1:2006" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as AdoptedEuropeanNorm" do
        expect(parsed).to be_a(described_class)
      end

      it "has adopted_identifier" do
        expect(parsed.adopted_identifier).not_to be_nil
      end

      it "delegates number" do
        expect(parsed.number).to eq("50131")
      end

      it "delegates part" do
        expect(parsed.part).to eq("1")
      end

      it "includes copublisher in output" do
        expect(parsed.to_s).to include("EN/CLC")
      end
    end
  end

  context "multi-digit numbers" do
    describe "BS EN 10000:2022" do
      subject { "BS EN 10000:2022" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as AdoptedEuropeanNorm" do
        expect(parsed).to be_a(described_class)
      end

      it "delegates number" do
        expect(parsed.number).to eq("10000")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end
end
