# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Ieee::Identifiers::Amendment do
  describe ".parse" do
    context "IEEE Std amendment patterns" do
      it "parses IEEE Std 802.3-2018/Amd 4-2020 and retains the amendment" do
        result = Pubid::Ieee.parse("IEEE Std 802.3-2018/Amd 4-2020")
        expect(result).to be_a(described_class)
        expect(result.number).to eq("4")
        expect(result.year).to eq("2020")
        expect(result.base).to be_a(Pubid::Ieee::Identifier)
        expect(result.base.code.to_s).to eq("802.3")
        expect(result.base.year).to eq("2018")
        expect(result.to_s).to eq("IEEE Std 802.3-2018/Amd 4-2020")
      end

      it "parses the no-space variant IEEE Std 802.3-2018/Amd4-2020" do
        result = Pubid::Ieee.parse("IEEE Std 802.3-2018/Amd4-2020")
        expect(result).to be_a(described_class)
        expect(result.number).to eq("4")
        expect(result.year).to eq("2020")
        expect(result.to_s).to eq("IEEE Std 802.3-2018/Amd 4-2020")
      end

      it "parses IEEE Std 1003.1-2001/Amd 2-2004" do
        result = Pubid::Ieee.parse("IEEE Std 1003.1-2001/Amd 2-2004")
        expect(result).to be_a(described_class)
        expect(result.number).to eq("2")
        expect(result.year).to eq("2004")
        expect(result.base.code.to_s).to eq("1003.1")
        expect(result.to_s).to eq("IEEE Std 1003.1-2001/Amd 2-2004")
      end
    end

    context "ISO/IEC/IEEE 8802.x amendment patterns" do
      it "parses ISO/IEC/IEEE 8802.3/Amd4-2021 and retains the amendment" do
        result = Pubid::Ieee.parse("ISO/IEC/IEEE 8802.3/Amd4-2021")
        expect(result).to be_a(described_class)
        expect(result.number).to eq("4")
        expect(result.year).to eq("2021")
        expect(result.base).to be_a(Pubid::Ieee::Identifier)
        expect(result.base.code.to_s).to eq("8802.3")
        expect(result.to_s).to eq("ISO/IEC/IEEE 8802.3/Amd 4-2021")
      end

      it "keeps distinct amendments distinct (no collapse onto the base)" do
        a = Pubid::Ieee.parse("ISO/IEC/IEEE 8802.3/Amd4-2021")
        b = Pubid::Ieee.parse("ISO/IEC/IEEE 8802.3/Amd7-2021")
        c = Pubid::Ieee.parse("ISO/IEC/IEEE 8802.3")

        expect(a.to_hash).not_to eq(b.to_hash)
        expect(a.to_hash).not_to eq(c.to_hash)
        expect(b.to_hash).not_to eq(c.to_hash)

        expect(a.to_s).not_to eq(b.to_s)
        expect(a.to_s).not_to eq(c.to_s)
      end
    end

    context "serialization" do
      let(:result) { Pubid::Ieee.parse("IEEE Std 802.3-2018/Amd 4-2020") }

      it "serializes as pubid:ieee:amendment with number/year + base" do
        hash = result.to_hash
        expect(hash["_type"]).to eq("pubid:ieee:amendment")
        expect(hash["number"]).to eq("4")
        expect(hash["year"]).to eq("2020")
        expect(hash["base"]).to be_a(Hash)
        expect(hash["base"]["number"]).to eq("802")
      end

      it "round-trips through from_hash" do
        expect(Pubid::Ieee::Identifier.from_hash(result.to_hash).to_hash)
          .to eq(result.to_hash)
      end

      it "keeps a non-empty root.number (relaton index key)" do
        expect(result.root.number.to_s).not_to be_empty
        expect(result.root.number.to_s).to eq("802")
      end
    end
  end
end
