# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Itu::Identifiers::Supplement do
  describe "basic supplement patterns" do
    context "ITU-T H Suppl. 1" do
      subject { "ITU-T H Suppl. 1" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses as Supplement" do
        expect(parsed).to be_a(described_class)
      end

      it "parses sector" do
        expect(parsed.sector.sector).to eq("T")
      end

      it "parses series" do
        expect(parsed.series.series).to eq("H")
      end

      it "parses supplement number" do
        expect(parsed.number).to eq("1")
      end

      it "has no base" do
        expect(parsed.base).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "ITU-T E.156 Suppl. 2" do
      subject { "ITU-T E.156 Suppl. 2" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses as Supplement" do
        expect(parsed).to be_a(described_class)
      end

      it "parses series" do
        expect(parsed.series.series).to eq("E")
      end

      it "parses base recommendation number" do
        expect(parsed.base).to be_a(Pubid::Itu::Identifiers::Recommendation)
        expect(parsed.base.code.number).to eq("156")
      end

      it "parses supplement number" do
        expect(parsed.number).to eq("2")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "ITU-T A Suppl. 2 (12/2022)" do
      subject { "ITU-T A Suppl. 2 (12/2022)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses as Supplement" do
        expect(parsed).to be_a(described_class)
      end

      it "parses series" do
        expect(parsed.series.series).to eq("A")
      end

      it "parses supplement number" do
        expect(parsed.number).to eq("2")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2022")
        expect(parsed.date.month).to eq("12")
      end

      it "has no base recommendation number" do
        expect(parsed.base).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  describe "supplement with different series" do
    context "ITU-T G.780 Suppl. 1" do
      subject { "ITU-T G.780 Suppl. 1" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses series" do
        expect(parsed.series.series).to eq("G")
      end

      it "parses base number" do
        expect(parsed.base.code.number).to eq("780")
      end

      it "parses supplement number" do
        expect(parsed.number).to eq("1")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "ITU-R V.574 Suppl. 3" do
      subject { "ITU-R V.574 Suppl. 3" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses sector" do
        expect(parsed.sector.sector).to eq("R")
      end

      it "parses series" do
        expect(parsed.series.series).to eq("V")
      end

      it "parses supplement number" do
        expect(parsed.number).to eq("3")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  describe "supplement with dates" do
    context "ITU-T H Suppl. 1 (06/2020)" do
      subject { "ITU-T H Suppl. 1 (06/2020)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses year" do
        expect(parsed.date.year).to eq("2020")
      end

      it "parses month" do
        expect(parsed.date.month).to eq("06")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "ITU-T E.156 Suppl. 2 (2018)" do
      subject { "ITU-T E.156 Suppl. 2 (2018)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses year without month" do
        expect(parsed.date.year).to eq("2018")
      end

      it "has no month" do
        expect(parsed.date.month).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  describe "multi-digit supplement numbers" do
    context "ITU-T H Suppl. 10" do
      subject { "ITU-T H Suppl. 10" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses multi-digit supplement number" do
        expect(parsed.number).to eq("10")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    context "ITU-T E.156 Suppl. 25" do
      subject { "ITU-T E.156 Suppl. 25" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses multi-digit supplement number" do
        expect(parsed.number).to eq("25")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  # A series-only supplement ("ITU-T A Suppl. 2") carries its whole identity
  # in sector + series; comparing only base/number/date made every series'
  # "Suppl. 2" equal, so an index search for "ITU-T A Suppl. 2" returned 42
  # rows.
  describe "equality" do
    def parse(str)
      Pubid::Itu.parse(str)
    end

    it "distinguishes supplements of different series" do
      expect(parse("ITU-T A Suppl. 2")).not_to eq(parse("ITU-T D Suppl. 2"))
      expect(parse("ITU-T H Suppl. 1")).not_to eq(parse("ITU-T G Suppl. 1"))
    end

    it "distinguishes supplements of different sectors" do
      expect(parse("ITU-T H Suppl. 1")).not_to eq(parse("ITU-R H Suppl. 1"))
    end

    it "does not match a different series once the date is ignored" do
      expect(
        parse("ITU-T A Suppl. 2").matches?(
          parse("ITU-T D Suppl. 2 (10/1984)"), ignore: %i[year month]
        ),
      ).to be false
    end

    it "still matches the same series once the date is ignored" do
      expect(
        parse("ITU-T A Suppl. 2").matches?(
          parse("ITU-T A Suppl. 2 (12/2022)"), ignore: %i[year month]
        ),
      ).to be true
    end

    it "keeps series-only supplements distinct as hash/set members" do
      expect(Set[parse("ITU-T A Suppl. 2"), parse("ITU-T D Suppl. 2")].size)
        .to eq(2)
    end

    it "distinguishes a supplement from an amendment, symmetrically" do
      supplement = parse("ITU-T G.989 Suppl. 1")
      amendment = parse("ITU-T G.989 Amd 1")

      expect(supplement).not_to eq(amendment)
      expect(amendment).not_to eq(supplement)
    end

    it "distinguishes a corrigendum from an errata, symmetrically" do
      corrigendum = parse("ITU-T G.9701 (2014) Cor. 1 (07/2016)")
      errata = parse("ITU-T G.9701 (2014) Err. 1 (07/2016)")

      expect(corrigendum).not_to eq(errata)
      expect(errata).not_to eq(corrigendum)
    end

    it "still equals the same identifier rebuilt from its hash" do
      %w[ITU-T\ E.156\ Suppl.\ 2 ITU-T\ A\ Suppl.\ 2].each do |str|
        id = parse(str)
        expect(Pubid::Itu::Identifier.from_hash(id.to_hash)).to eq(id)
      end
    end
  end
end
