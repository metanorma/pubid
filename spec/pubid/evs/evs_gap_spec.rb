# frozen_string_literal: true

require "spec_helper"

# The EVS-provided prefix/supplement/language list (pubid#517-list): the
# prefixes (EVS, EVS-EN, EVS-EN ISO, EVS-EN ISO/IEC, EVS-IEC, EVS-ISO),
# the supplements (A/AMD, +A, /A, COR/AC, +COR, NA, +NA, /NA), the types
# (TS, TR, CWA), the pr drafts, and the language codes (et, en, et-en).
RSpec.describe "EVS prefix/supplement/language coverage" do
  describe "prefixes" do
    {
      "EVS 921:2019" => "EVS 921:2019",
      "EVS-EN 18216:2026" => "EVS-EN 18216:2026",
      "EVS-EN ISO 9001:2015" => "EVS-EN ISO 9001:2015",
      "EVS-EN ISO/IEC 17025:2017" => "EVS-EN ISO/IEC 17025:2017",
      "EVS-IEC 62368-1:2020" => "EVS-IEC 62368-1:2020",
      "EVS-ISO 9001:2015" => "EVS-ISO 9001:2015",
    }.each do |input, expected|
      it "round-trips #{input.inspect}" do
        expect(Pubid::Evs::Identifier.parse(input).to_s).to eq(expected)
      end
    end
  end

  describe "amendment spellings" do
    it "round-trips +A with and without year" do
      expect(Pubid::Evs::Identifier.parse("EVS-EN 71-1:2011+A1").to_s).to eq("EVS-EN 71-1:2011+A1")
      expect(Pubid::Evs::Identifier.parse("EVS-EN 71-1:2011+A1:2014").to_s).to eq("EVS-EN 71-1:2011+A1:2014")
    end

    it "round-trips the /A only-amendment form" do
      expect(Pubid::Evs::Identifier.parse("EVS-EN 71-1:2011/A1:2014").to_s).to eq("EVS-EN 71-1:2011/A1:2014")
    end

    it "round-trips the AMD spelling" do
      expect(Pubid::Evs::Identifier.parse("EVS-EN 71-1:2011 AMD1:2014").to_s)
        .to eq("EVS-EN 71-1:2011 AMD1:2014")
    end
  end

  describe "corrigendum spellings" do
    it "round-trips +COR with and without year" do
      expect(Pubid::Evs::Identifier.parse("EVS-EN 50581:2012+COR:2015").to_s)
        .to eq("EVS-EN 50581:2012+COR:2015")
      expect(Pubid::Evs::Identifier.parse("EVS-EN 50581:2012+COR").to_s)
        .to eq("EVS-EN 50581:2012+COR")
    end

    it "round-trips /COR and the AC spelling" do
      expect(Pubid::Evs::Identifier.parse("EVS-EN 50581:2012/COR:2015").to_s)
        .to eq("EVS-EN 50581:2012/COR:2015")
      expect(Pubid::Evs::Identifier.parse("EVS-EN 50581:2012 AC:2015").to_s)
        .to eq("EVS-EN 50581:2012 AC:2015")
    end

    it "keeps the CEN +AC spelling" do
      expect(Pubid::Evs::Identifier.parse("EVS-EN 50581:2012+AC:2015").to_s)
        .to eq("EVS-EN 50581:2012+AC:2015")
    end
  end

  describe "national annex" do
    it "round-trips +NA with and without year" do
      expect(Pubid::Evs::Identifier.parse("EVS-EN 1993-1-1:2005+NA:2010").to_s)
        .to eq("EVS-EN 1993-1-1:2005+NA:2010")
      expect(Pubid::Evs::Identifier.parse("EVS-EN 1993-1-1:2005+NA").to_s)
        .to eq("EVS-EN 1993-1-1:2005+NA")
    end

    it "round-trips the /NA only form" do
      expect(Pubid::Evs::Identifier.parse("EVS-EN 1993-1-1:2005/NA").to_s)
        .to eq("EVS-EN 1993-1-1:2005/NA")
    end
  end

  describe "types" do
    it "round-trips CWA on the adopted prefix" do
      expect(Pubid::Evs::Identifier.parse("EVS-CWA 16994:2017").to_s).to eq("EVS-CWA 16994:2017")
    end
  end

  describe "pr drafts" do
    it "round-trips the pr prefix on every prefix family" do
      expect(Pubid::Evs::Identifier.parse("prEVS-EN 100:2026").to_s).to eq("prEVS-EN 100:2026")
      expect(Pubid::Evs::Identifier.parse("prEVS-EN ISO 100:2026").to_s).to eq("prEVS-EN ISO 100:2026")
      expect(Pubid::Evs::Identifier.parse("prEVS 100:2026").to_s).to eq("prEVS 100:2026")
    end
  end

  describe "language codes" do
    {
      "EVS 811:2018 et" => "et",
      "EVS-EN 18216:2026 en" => "en",
      "EVS 811:2018 et-en" => "et-en",
      "EVS-EN 1993-1-1:2005+NA:2010 et" => "et",
    }.each do |input, language|
      it "round-trips #{input.inspect}" do
        id = Pubid::Evs::Identifier.parse(input)
        expect(id.to_s).to eq(input)
        expect(id.language).to eq(language)
      end
    end
  end

  describe "urn round-trips" do
    {
      "EVS-EN 18216:2026" => "urn:evs:en:18216:2026",
      "EVS-EN ISO 9001:2015/A1:2024" => "urn:evs:en:iso:9001:2015:amd:1:2024",
      "EVS-ISO 9001:2015" => "urn:evs:iso:9001:2015",
      "EVS-IEC 62368-1:2020" => "urn:evs:iec:62368-1:2020",
      "EVS 921:2019" => "urn:evs:921:2019",
      "EVS-TS 1:2019" => "urn:evs:ts:1:2019",
      "EVS-EN 1993-1-1:2005+NA:2010 et" => "urn:evs:en:1993-1-1:2005:na:2010:et",
      "prEVS-EN 100:2026" => "urn:evs:pr:en:100:2026",
    }.each do |input, urn|
      it "generates #{urn} from #{input.inspect}" do
        expect(Pubid::Evs::Identifier.parse(input).to_urn).to eq(urn)
      end

      it "parses #{urn} back to #{input.inspect}" do
        expect(Pubid::Evs::UrnParser.new.parse_urn(urn).to_s).to eq(input)
      end
    end
  end

  describe "the wave-2 catalogue rows (pubid ruling 2026-10-13)" do
    it "renders the adopted TS face without the TS marker" do
      # "EVS-EN TS ..." and "EVS-EN/TS ..." normalize onto "EVS-EN ..." —
      # the TS-ness of an EN adoption is metadata, not identity.
      expect(Pubid::Evs::Identifier.parse("EVS-EN TS 16798-1:2019").to_s)
        .to eq("EVS-EN 16798-1:2019")
      expect(Pubid::Evs::Identifier.parse("EVS-EN/TS 16798-1:2019").to_s)
        .to eq("EVS-EN 16798-1:2019")
    end

    it "rejects EN TR (a technical report is CEN/TR or CLC/TR)" do
      expect { Pubid::Evs::Identifier.parse("EVS-EN TR 16798:2021") }
        .to raise_error(Pubid::Errors::ParseError)
    end

    it "round-trips the ETSI-style version rows" do
      expect(Pubid::Evs::Identifier.parse("EVS-EN 302 326-2 V2.2.1:2026").to_s)
        .to eq("EVS-EN 302 326-2 V2.2.1:2026")
      expect(Pubid::Evs::Identifier.parse("EVS-EN 301 406-1 V3.2.1:2026").to_s)
        .to eq("EVS-EN 301 406-1 V3.2.1:2026")
    end

    it "round-trips the plain rows" do
      expect(Pubid::Evs::Identifier.parse("EVS 906:2026").to_s).to eq("EVS 906:2026")
      expect(Pubid::Evs::Identifier.parse("EVS 945:2023").to_s).to eq("EVS 945:2023")
      expect(Pubid::Evs::Identifier.parse("EVS-EN IEC 61000-4-30:2026").to_s)
        .to eq("EVS-EN IEC 61000-4-30:2026")
    end
  end
end
