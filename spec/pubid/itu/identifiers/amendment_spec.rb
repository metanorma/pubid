# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Itu::Identifiers::Amendment do
  describe "basic amendment patterns" do
    context "ITU-T G.989 Amd 1" do
      subject { "ITU-T G.989 Amd 1" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses as Amendment" do
        expect(parsed).to be_a(described_class)
      end

      it "parses sector" do
        expect(parsed.sector.sector).to eq("T")
      end

      it "parses series" do
        expect(parsed.series.series).to eq("G")
      end

      it "parses base recommendation number" do
        expect(parsed.base).to be_a(Pubid::Itu::Identifiers::Recommendation)
        expect(parsed.base.code.number).to eq("989")
      end

      it "parses amendment number" do
        expect(parsed.number).to eq("1")
      end

      it "normalizes 'Amd' to the canonical 'Amd.'" do
        expect(parsed.to_s).to eq("ITU-T G.989 Amd. 1")
      end
    end

    context "ITU-T G.989 Amd. 1" do
      subject { "ITU-T G.989 Amd. 1" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses as Amendment" do
        expect(parsed).to be_a(described_class)
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  describe "amendment with dates" do
    context "ITU-T G.780/Y.1351 Amd. 1 (2004)" do
      subject { "ITU-T G.780/Y.1351 Amd. 1 (2004)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses as Amendment" do
        expect(parsed).to be_a(described_class)
      end

      it "parses series" do
        expect(parsed.series.series).to eq("G")
      end

      it "parses base number" do
        expect(parsed.base.code.number).to eq("780")
      end

      it "parses amendment number" do
        expect(parsed.number).to eq("1")
      end

      it "parses year" do
        expect(parsed.date.year).to eq("2004")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "ITU-T G.989 Amd. 2 (06/2018)" do
      subject { "ITU-T G.989 Amd. 2 (06/2018)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses year" do
        expect(parsed.date.year).to eq("2018")
      end

      it "parses month" do
        expect(parsed.date.month).to eq("06")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "ITU-T M.3016.1 Amd. 1 (2020)" do
      subject { "ITU-T M.3016.1 Amd. 1 (2020)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses subseries" do
        expect(parsed.base.code.subseries).to eq("1")
      end

      it "parses amendment number" do
        expect(parsed.number).to eq("1")
      end

      it "parses year" do
        expect(parsed.date.year).to eq("2020")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  describe "ITU-R amendments" do
    context "ITU-R V.574-5 Amd. 1" do
      subject { "ITU-R V.574-5 Amd. 1" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses sector" do
        expect(parsed.sector.sector).to eq("R")
      end

      it "parses series" do
        expect(parsed.series.series).to eq("V")
      end

      it "parses base number with part" do
        expect(parsed.base.code.number).to eq("574")
        expect(parsed.base.code.parts.first).to eq("5")
      end

      it "parses amendment number" do
        expect(parsed.number).to eq("1")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "ITU-R SA.364-6 Amd. 2 (2015)" do
      subject { "ITU-R SA.364-6 Amd. 2 (2015)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses two-letter series" do
        expect(parsed.series.series).to eq("SA")
      end

      it "parses amendment number" do
        expect(parsed.number).to eq("2")
      end

      it "parses year" do
        expect(parsed.date.year).to eq("2015")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  describe "multi-digit amendment numbers" do
    context "ITU-T G.989 Amd. 10" do
      subject { "ITU-T G.989 Amd. 10" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses multi-digit amendment number" do
        expect(parsed.number).to eq("10")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "ITU-T G.780 Amd. 25 (2019)" do
      subject { "ITU-T G.780 Amd. 25 (2019)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses multi-digit amendment number" do
        expect(parsed.number).to eq("25")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end
end
