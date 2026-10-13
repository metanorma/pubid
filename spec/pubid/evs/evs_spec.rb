# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/pubid/evs"

RSpec.describe Pubid::Evs do
  describe "national adoptions of European Standards" do
    it "parses a plain EN adoption" do
      id = described_class.parse("EVS-EN 18216:2026")
      expect(id).to be_a(Pubid::Evs::Identifiers::NationalAdoption)
      expect(id.to_s).to eq("EVS-EN 18216:2026")
      expect(id.base.number.to_s).to eq("18216")
      expect(id.base.year.to_s).to eq("2026")
    end

    it "parses an EN ISO adoption" do
      id = described_class.parse("EVS-EN ISO 14001:2026")
      expect(id.base).to be_a(Pubid::CenCenelec::Identifiers::AdoptedEuropeanNorm)
      expect(id.to_s).to eq("EVS-EN ISO 14001:2026")
    end

    it "parses an EN ISO/IEC adoption" do
      id = described_class.parse("EVS-EN ISO/IEC 27017:2026")
      expect(id.base).to be_a(Pubid::CenCenelec::Identifiers::AdoptedEuropeanNorm)
      expect(id.to_s).to eq("EVS-EN ISO/IEC 27017:2026")
    end

    it "parses an amendment adoption" do
      id = described_class.parse("EVS-EN ISO 9001:2015/A1:2024")
      expect(id.to_s).to eq("EVS-EN ISO 9001:2015/A1:2024")
      expect(id.base.root.number.to_s).to eq("9001")
      expect(id.base.root.year.to_s).to eq("2015")
    end

    it "parses through the global Pubid.parse dispatcher" do
      expect(Pubid.parse("EVS-EN ISO/IEC 27701:2025")).to be_a(Pubid::Evs::Identifiers::NationalAdoption)
    end
  end

  describe "separator handling" do
    it "preserves the printed space separator" do
      id = described_class.parse("EVS EN 18216:2026")
      expect(id.to_s).to eq("EVS EN 18216:2026")
    end

    it "defaults to the hyphen separator" do
      id = Pubid::Evs::Identifiers::NationalAdoption.new(
        base: Pubid::CenCenelec.parse("EN 18216:2026"),
      )
      expect(id.to_s).to eq("EVS-EN 18216:2026")
    end
  end

  describe "URN generation" do
    it "mirrors the CEN namespace with the national prefix" do
      expect(described_class.parse("EVS-EN 18216:2026").to_urn)
        .to eq("urn:evs:en:18216:2026")
      expect(described_class.parse("EVS-EN ISO 14001:2026").to_urn)
        .to eq("urn:evs:en:iso:14001:2026")
      expect(described_class.parse("EVS-EN ISO/IEC 27017:2026").to_urn)
        .to eq("urn:evs:en:iso-iec:27017:2026")
      expect(described_class.parse("EVS-EN ISO 9001:2015/A1:2024").to_urn)
        .to eq("urn:evs:en:iso:9001:2015:amd:1:2024")
    end
  end

  # The wrapped document is exposed as `base`, the uniform parent accessor, so
  # `#root` walks it and relaton keys the adoption under the origin standard's
  # number. The old name `adopted_identifier` left root.number empty.
  describe "the uniform parent accessor" do
    {
      "EVS-EN 18216:2026" => "18216",
      "EVS-EN ISO 14001:2026" => "14001",
      "EVS-EN ISO/IEC 27017:2026" => "27017",
      "EVS-EN ISO 9001:2015/A1:2024" => "9001",
    }.each do |ref, number|
      it "keys #{ref} under #{number}" do
        id = described_class.parse(ref)

        expect(id.root).to eq(id.base.root)
        expect(id.root.number.to_s).to eq(number)
      end
    end

    it "serializes the wrapped document under \"base\"" do
      hash = described_class.parse("EVS-EN 18216:2026").to_hash

      expect(hash.keys).to eq(%w[_type base])
    end
  end

  # pubid#383: from_hash raised InvalidFormatError on every EVS hash. The
  # `type` default was the Symbol :evs_en, so to_hash dropped it as a default
  # and from_hash then cast the Symbol into a Components::Type.
  describe "from_hash round trip" do
    [
      "EVS-EN 18216:2026",
      "EVS EN ISO 14001:2026",
      "EVS-EN ISO/IEC 27017:2026",
      "EVS-EN ISO 9001:2015/A1:2024",
    ].each do |ref|
      context "with #{ref}" do
        let(:id) { described_class.parse(ref) }

        it "rebuilds an equal identifier through the flavor handle" do
          restored = Pubid::Evs::Identifier.from_hash(id.to_hash)

          expect(restored).to be_a(Pubid::Evs::Identifiers::NationalAdoption)
          expect(restored).to eq(id)
          expect(restored.to_hash).to eq(id.to_hash)
          expect(restored.to_s).to eq(ref)
          expect(restored.to_urn).to eq(id.to_urn)
        end

        it "rebuilds the same class through Pubid.from_hash" do
          expect(Pubid.from_hash(id.to_hash)).to eq(id)
        end
      end
    end

    it "does not serialize the defaulted type" do
      expect(described_class.parse("EVS-EN 18216:2026").to_hash)
        .not_to have_key("type")
    end
  end

  describe "URN parsing" do
    it "parses URNs back into national adoptions" do
      id = Pubid.parse("urn:evs:en:iso:14001:2026", format: :urn)
      expect(id).to be_a(Pubid::Evs::Identifiers::NationalAdoption)
      expect(id.to_s).to eq("EVS-EN ISO 14001:2026")
    end

    it "round-trips the amendment URN" do
      id = Pubid.parse("urn:evs:en:iso:9001:2015:amd:1:2024", format: :urn)
      expect(id.to_s).to eq("EVS-EN ISO 9001:2015/A1:2024")
      expect(id.to_urn).to eq("urn:evs:en:iso:9001:2015:amd:1:2024")
    end

    it "rejects an unsupported type" do
      # TS is supported now (the EVS prefix list); a type outside the list
      # ("xx", "hd" without its CEN adoption spine) still rejects.
      expect do
        Pubid.parse("urn:evs:xx:18216:2026", format: :urn)
      end.to raise_error(Pubid::Errors::ParseError)
    end
  end

  describe "invalid input" do
    it "rejects non-EVS strings" do
      expect { described_class.parse("BS EN 18216:2026") }
        .to raise_error(Parslet::ParseFailed)
    end

    it "rejects garbage after the adoption prefix" do
      expect { described_class.parse("EVS-EN nonsense!") }
        .to raise_error(Parslet::ParseFailed)
    end
  end

  describe "wrapped identifier classes" do
    it "wraps a plain EuropeanNorm" do
      expect(described_class.parse("EVS-EN 18216:2026").base)
        .to be_a(Pubid::CenCenelec::Identifiers::EuropeanNorm)
    end

    it "wraps an AdoptedEuropeanNorm for EN ISO" do
      expect(described_class.parse("EVS-EN ISO 14001:2026").base)
        .to be_a(Pubid::CenCenelec::Identifiers::AdoptedEuropeanNorm)
    end

    it "wraps an Amendment for /A1" do
      expect(described_class.parse("EVS-EN ISO 9001:2015/A1:2024").base)
        .to be_a(Pubid::CenCenelec::Identifiers::Amendment)
    end
  end

  describe "URN separator normalization" do
    it "normalizes the space separator to hyphen through a URN round trip" do
      id = described_class.parse("EVS EN 18216:2026")
      back = Pubid.parse(id.to_urn, format: :urn)
      expect(back.to_s).to eq("EVS-EN 18216:2026")
    end
  end

  describe "corrigendum URN" do
    it "round-trips a corrigendum adoption" do
      id = Pubid.parse("urn:evs:en:iso:9001:2015:cor:1:2024", format: :urn)
      expect(id.to_s).to eq("EVS-EN ISO 9001:2015/AC1:2024")
      expect(id.to_urn).to eq("urn:evs:en:iso:9001:2015:cor:1:2024")
    end
  end

  describe "UrnGenerator guard" do
    it "rejects a non-CEN adopted identifier" do
      id = Pubid::Evs::Identifiers::NationalAdoption.new(
        base: Pubid::Iso.parse("ISO 9001:2015"),
      )
      expect do
        id.to_urn
      end.to raise_error(Pubid::Errors::ParseError, 
                         /expected adopted CEN URN/)
    end
  end

  describe "case sensitivity" do
    it "rejects a lowercase national prefix" do
      expect { described_class.parse("evs-en 18216:2026") }
        .to raise_error(Parslet::ParseFailed)
    end
  end
end
