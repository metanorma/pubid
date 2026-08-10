# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Ieee::Identifiers::Nesc::Standard do
  describe "#parse" do
    context "C2-YYYY format (basic)" do
      let(:input) { "C2-1997 National Electric Safety Code (NESC)" }
      let(:parsed) { Pubid::Ieee.parse(input) }

      it "parses as NESC::Standard" do
        expect(parsed).to be_a(described_class)
      end

      it "extracts year" do
        expect(parsed.year).to eq("1997")
      end

      it "extracts code" do
        expect(parsed.code.number).to eq("2")
      end

      it "round-trips correctly" do
        expected = "C2-1997 National Electrical Safety Code"
        expect(parsed.to_s).to eq(expected)
      end
    end

    context "C2-YYYY format (no NESC suffix)" do
      let(:input) { "C2-2012 National Electrical Safety Code" }
      let(:parsed) { Pubid::Ieee.parse(input) }

      it "parses as NESC::Standard" do
        expect(parsed).to be_a(described_class)
      end

      it "extracts year" do
        expect(parsed.year).to eq("2012")
      end

      it "round-trips correctly" do
        expect(parsed.to_s).to eq(input)
      end
    end

    context "C2-YYYY with comma separator" do
      let(:input) { "C2-2007, National Electrical Safety Code" }
      let(:parsed) { Pubid::Ieee.parse(input) }

      it "parses as NESC::Standard" do
        expect(parsed).to be_a(described_class)
      end

      it "extracts year" do
        expect(parsed.year).to eq("2007")
      end

      it "round-trips without comma" do
        expected = "C2-2007 National Electrical Safety Code"
        expect(parsed.to_s).to eq(expected)
      end
    end

    context "C2-YYYY typo variation (Electric vs Electrical)" do
      let(:input) { "C2-2002 National Electric Safety Code" }
      let(:parsed) { Pubid::Ieee.parse(input) }

      it "parses as NESC::Standard" do
        expect(parsed).to be_a(described_class)
      end

      it "normalizes to 'Electrical'" do
        expected = "C2-2002 National Electrical Safety Code"
        expect(parsed.to_s).to eq(expected)
      end
    end
  end
end
