# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Ieee::Identifiers::Corrigendum do
  describe ".parse" do
    context "basic corrigendum patterns" do
      it "parses IEEE Std 535-2013/Cor. 1-2017" do
        result = Pubid::Ieee.parse("IEEE Std 535-2013/Cor. 1-2017")
        expect(result).to be_a(described_class)
        expect(result.number).to eq("1")
        expect(result.year).to eq("2017")
        expect(result.base).to be_a(Pubid::Ieee::Identifier)
        expect(result.base.code.to_s).to eq("535")
        expect(result.base.year).to eq("2013")
        expect(result.to_s).to eq("IEEE Std 535-2013/Cor. 1-2017")
      end

      it "parses IEEE Std 802.1AC-2016/Cor 1-2018 (without period)" do
        result = Pubid::Ieee.parse("IEEE Std 802.1AC-2016/Cor 1-2018")
        expect(result).to be_a(described_class)
        expect(result.number).to eq("1")
        expect(result.year).to eq("2018")
        expect(result.to_s).to eq("IEEE Std 802.1AC-2016/Cor. 1-2018")
      end

      it "parses IEEE Std C37.41-2016/Cor 1-2017" do
        result = Pubid::Ieee.parse("IEEE Std C37.41-2016/Cor 1-2017")
        expect(result).to be_a(described_class)
        expect(result.number).to eq("1")
        expect(result.year).to eq("2017")
        expect(result.base.code.to_s).to eq("C37.41")
        expect(result.to_s).to eq("IEEE Std C37.41-2016/Cor. 1-2017")
      end

      it "parses IEEE Std C95.1-2019/Cor2-2020 (no space before number)" do
        result = Pubid::Ieee.parse("IEEE Std C95.1-2019/Cor2-2020")
        expect(result).to be_a(described_class)
        expect(result.number).to eq("2")
        expect(result.year).to eq("2020")
        expect(result.to_s).to eq("IEEE Std C95.1-2019/Cor. 2-2020")
      end
    end

    context "corrigendum with parenthetical descriptions" do
      it "parses corrigendum with 'Corrigenda of' description" do
        result = Pubid::Ieee.parse("IEEE Std 535-2013/Cor. 1-2017 (Corrigenda of IEEE Std 535-2013)")
        expect(result).to be_a(described_class)
        expect(result.number).to eq("1")
        expect(result.year).to eq("2017")
      end

      it "parses corrigendum with 'Corrigenda to' description" do
        result = Pubid::Ieee.parse("IEEE Std 802.1AC-2016/Cor 1-2018 (Corrigenda to IEEE Std 802.1AC-2016)")
        expect(result).to be_a(described_class)
        expect(result.number).to eq("1")
        expect(result.year).to eq("2018")
      end
    end

    context "round-trip fidelity" do
      it "maintains format through parse and render" do
        original = "IEEE Std 535-2013/Cor. 1-2017"
        parsed = Pubid::Ieee.parse(original)
        expect(parsed.to_s).to eq(original)
      end
    end
  end
end
