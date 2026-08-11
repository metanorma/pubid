# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Itu::Identifiers::Errata do
  describe "errata directly on a recommendation — issue #230" do
    context "ITU-T G.9701 (2014) Err. 1 (07/2016)" do
      subject { "ITU-T G.9701 (2014) Err. 1 (07/2016)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses as Errata" do
        expect(parsed).to be_a(described_class)
      end

      it "parses series" do
        expect(parsed.series.series).to eq("G")
      end

      it "parses base recommendation" do
        expect(parsed.base).to be_a(Pubid::Itu::Identifiers::Recommendation)
        expect(parsed.base.code.number).to eq("9701")
      end

      it "parses base year" do
        expect(parsed.base.date.year).to eq("2014")
      end

      it "parses errata number" do
        expect(parsed.number).to eq("1")
      end

      it "parses errata date" do
        expect(parsed.date.year).to eq("2016")
        expect(parsed.date.month).to eq("07")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "ITU-T G.9701 (2014) Err. 1 (without errata date)" do
      subject { "ITU-T G.9701 (2014) Err. 1" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses as Errata" do
        expect(parsed).to be_a(described_class)
      end

      it "has no errata date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  describe "errata on another supplement (chained) — issue #230" do
    # Errata on an Amendment.
    context "ITU-T G.9701 (2014) Amd. 3 Err. 1 (12/2017)" do
      let(:parsed) { Pubid::Itu.parse("ITU-T G.9701 (2014) Amd. 3 Err. 1 (12/2017)") }

      it "parses as Errata" do
        expect(parsed).to be_a(described_class)
      end

      it "has an Amendment as its base" do
        expect(parsed.base).to be_a(Pubid::Itu::Identifiers::Amendment)
      end

      it "the Amendment's base is the Recommendation" do
        expect(parsed.base.base).to be_a(Pubid::Itu::Identifiers::Recommendation)
        expect(parsed.base.base.code.number).to eq("9701")
      end

      it "parses errata number and date" do
        expect(parsed.number).to eq("1")
        expect(parsed.date.year).to eq("2017")
        expect(parsed.date.month).to eq("12")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq("ITU-T G.9701 (2014) Amd. 3 Err. 1 (12/2017)")
      end
    end

    context "ITU-T G.9701 (2014) Cor. 1 Err. 1 (06/2017)" do
      subject { "ITU-T G.9701 (2014) Cor. 1 Err. 1 (06/2017)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses as Errata" do
        expect(parsed).to be_a(described_class)
      end

      it "has a Corrigendum as its base" do
        expect(parsed.base).to be_a(Pubid::Itu::Identifiers::Corrigendum)
      end

      it "parses errata number and date" do
        expect(parsed.number).to eq("1")
        expect(parsed.date.year).to eq("2017")
        expect(parsed.date.month).to eq("06")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  describe "Errata vs Corrigendum" do
    it "treats Err. 1 and Cor. 1 as distinct" do
      errata = Pubid::Itu.parse("ITU-T G.9701 (2014) Err. 1 (07/2016)")
      corrigendum = Pubid::Itu.parse("ITU-T G.9701 (2014) Cor. 1 (07/2016)")
      expect(errata).not_to eq(corrigendum)
    end
  end
end
