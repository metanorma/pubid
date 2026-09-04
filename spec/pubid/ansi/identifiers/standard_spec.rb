# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Ansi::Identifiers::Standard do
  # ========================================
  # Standard (76 IDs, 26%)
  # ========================================
  describe "parses letter-less simple standard" do
    subject { "ANSI 802.3-2012" }

    let(:parsed) { Pubid::Ansi.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("802.3")
      expect(parsed.part).to eq("2012")
      expect(parsed.to_s).to eq(subject)
    end
  end

  describe "parses lettered standard with dash year" do
    subject { "ANSI C135.14-1979" }

    let(:parsed) { Pubid::Ansi.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("C135.14")
      expect(parsed.part).to eq("1979")
      expect(parsed.to_s).to eq(subject)
    end
  end

  describe "parses lettered standard with complex number and dash year" do
    subject { "ANSI C37.06.1-2000" }

    let(:parsed) { Pubid::Ansi.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("C37.06.1")
      expect(parsed.part).to eq("2000")
      expect(parsed.to_s).to eq(subject)
    end
  end

  describe "parses lettered standard with letter suffix and dash year" do
    subject { "ANSI N323D-2002" }

    let(:parsed) { Pubid::Ansi.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("N323D")
      expect(parsed.part).to eq("2002")
      expect(parsed.to_s).to eq(subject)
    end
  end

  describe "parses co-published standard with slash" do
    subject { "ANSI/ASME B16.5" }

    let(:parsed) { Pubid::Ansi.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("B16.5")
      expect(parsed.part).to be_nil
      expect(parsed.date).to be_nil
      expect(parsed.copublishers.first.body).to eq("ASME")
    end
  end

  describe "parses co-published standard with slash and dash year" do
    subject { "ANSI/ASTM E1527-2013" }

    let(:parsed) { Pubid::Ansi.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("E1527")
      expect(parsed.part).to eq("2013")
      expect(parsed.copublishers.first.body).to eq("ASTM")
    end
  end

  describe "parses co-published standard with IEC" do
    subject { "ANSI/IEC 60601-1" }

    let(:parsed) { Pubid::Ansi.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("60601")
      expect(parsed.part).to eq("1")
      expect(parsed.copublishers.first.body).to eq("IEC")
    end
  end

  describe "parses co-published standard with IEEE" do
    subject { "ANSI/IEEE 1-1986" }

    let(:parsed) { Pubid::Ansi.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("1")
      expect(parsed.part).to eq("1986")
      expect(parsed.copublishers.first.body).to eq("IEEE")
    end
  end

  describe "parses co-published standard with IEEE and complex number" do
    subject { "ANSI/IEEE 802.3j-1993" }

    let(:parsed) { Pubid::Ansi.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("802.3j")
      expect(parsed.part).to eq("1993")
      expect(parsed.copublishers.first.body).to eq("IEEE")
    end
  end

  describe "parses co-published standard with IEEE and lettered complex number" do
    subject { "ANSI/IEEE C67.92-1987" }

    let(:parsed) { Pubid::Ansi.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("C67.92")
      expect(parsed.part).to eq("1987")
      expect(parsed.copublishers.first.body).to eq("IEEE")
    end
  end

  describe "parses co-published standard with ISO and colon year" do
    subject { "ANSI/ISO 9899:1990" }

    let(:parsed) { Pubid::Ansi.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("9899")
      expect(parsed.date.year).to eq("1990")
      expect(parsed.copublishers.first.body).to eq("ISO")
      expect(parsed.to_s).to eq(subject)
    end
  end

  describe "parses co-published standard with SAE and no year" do
    subject { "ANSI/SAE J1939" }

    let(:parsed) { Pubid::Ansi.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("J1939")
      expect(parsed.part).to be_nil
      expect(parsed.date).to be_nil
      expect(parsed.copublishers.first.body).to eq("SAE")
    end
  end
end
