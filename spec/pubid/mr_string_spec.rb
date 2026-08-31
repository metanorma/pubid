# frozen_string_literal: true

# Issue #142: `Identifier#to_mr_string` must be lossless — the MR string has to
# carry every segment needed to reconstruct the identifier. Earlier behavior
# dropped sub-segments of multi-segment part numbers, the base identifier of
# any supplement, and most flavor-specific attributes (NIST series, IEEE code,
# CSA publisher prefix, JIS series letter, SAE type, …).
#
# These tests pin both directions:
# - `to_mr_string` emits the expected segments.
# - `Pubid::Parsers::MrString.parse(mr)` round-trips back to an equivalent id.
# - Distinct identifiers never collide on `to_mr_string` (the contrapositive
#   of "MR carries enough to reconstruct").
#
# Follow-up convention: MR is ALL LOWERCASE and filename-safe
# (`[a-z0-9.-]` + `_` as supplement separator + `-` as copublisher separator)
# for every flavor except NIST (whose MR shape is fixed by the pubid
# standard). `to_slug` projects the MR into a lowercase slug; for non-NIST
# flavors that is just `to_mr_string`, for NIST it lowercases.
require "spec_helper"

RSpec.describe "Lossless MR string (issue #142)" do
  describe "ISO" do
    it "preserves every part segment" do
      id = Pubid::Iso.parse("ISO 1234-1-2-3:2020")
      expect(id.to_mr_string).to eq("iso.1234-1-2-3.2020")
    end

    it "preserves the year separator (4-digit year)" do
      id = Pubid::Iso.parse("ISO 9001:2015")
      expect(id.to_mr_string).to eq("iso.9001.2015")
    end

    it "preserves copublishers as `-` (filename-safe)" do
      id = Pubid::Iso.parse("ISO/IEC 17031-1:2020")
      expect(id.to_mr_string).to eq("iso-iec.17031-1.2020")
    end

    it "preserves the type code (lowercase)" do
      id = Pubid::Iso.parse("ISO/TR 14627:2017")
      expect(id.to_mr_string).to eq("iso.tr.14627.2017")
    end

    it "preserves undated references (:--)" do
      id = Pubid::Iso.parse("ISO 16634:--")
      expect(id.to_mr_string).to eq("iso.16634.--")
    end

    it "preserves languages as hyphen-joined, no parens" do
      id = Pubid::Iso.parse("ISO 9001:2015(en,fr)")
      expect(id.to_mr_string).to eq("iso.9001.2015.en-fr")
    end

    it "preserves the supplement base (amendment) via `_` separator" do
      id = Pubid::Iso.parse("ISO 9001:2015/Amd 1:2020")
      expect(id.to_mr_string).to eq("iso.9001.2015_amd.1.2020")
    end

    it "preserves chained supplements (Cor over Amd over IS)" do
      id = Pubid::Iso.parse("ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017")
      expect(id.to_mr_string).to eq("iso-iec.13818-1.2015_amd.3.2016_cor.1.2017")
    end

    it "preserves yyyy-mm dates" do
      id = Pubid::Iso.parse("ISO 16634:2024-03")
      expect(id.to_mr_string).to eq("iso.16634.2024-03")
    end

    it "preserves yyyy-mm-dd dates" do
      id = Pubid::Iso.parse("ISO 16634:2024-03-15")
      expect(id.to_mr_string).to eq("iso.16634.2024-03-15")
    end
  end

  describe "IEC" do
    it "preserves the supplement base" do
      id = Pubid::Iec.parse("IEC 60050-351:2013/AMD1:2016")
      expect(id.to_mr_string).to eq("iec.60050-351.2013_amd.1.2016")
    end

    it "preserves multi-segment parts" do
      id = Pubid::Iec.parse("IEC 60601-1-11:2010")
      expect(id.to_mr_string).to eq("iec.60601-1-11.2010")
    end
  end

  describe "NIST — keeps its own MR shape, slug lowercases it" do
    it "to_mr_string preserves the series code (uppercase, per standard)" do
      id = Pubid::Nist.parse("NIST SP 800-53")
      # NIST has its own MR format; to_mr_string delegates to to_mr_style.
      expect(id.to_mr_string).to eq(id.to_mr_style)
      expect(id.to_mr_string).to eq("NIST.SP.800-53")
    end

    it "to_mr_string preserves the series for Technical Notes" do
      id = Pubid::Nist.parse("NIST TN 1297")
      expect(id.to_mr_string).to eq("NIST.TN.1297")
    end

    it "to_slug lowercases the MR for filesystem/URL use" do
      id = Pubid::Nist.parse("NIST SP 800-53")
      expect(id.to_slug).to eq("nist.sp.800-53")
    end
  end

  describe "IEEE" do
    it "preserves the code and year (lowercase)" do
      id = Pubid::Ieee.parse("IEEE Std 802.3-2018")
      expect(id.to_mr_string).to eq("ieee.std.802.3.2018")
    end

    it "preserves the supplement (Corrigendum)" do
      id = Pubid::Ieee.parse("IEEE Std 802.3-2018/Cor 1:2019")
      expect(id.to_mr_string).to eq("ieee.std.802.3.2018_cor.1.2019")
    end
  end

  describe "BSI" do
    it "emits publisher.number.year" do
      id = Pubid::Bsi.parse("BS 490:1972")
      expect(id.to_mr_string).to eq("bs.490.1972")
    end
  end

  describe "CEN/CENELEC" do
    it "emits publisher.number.year" do
      id = Pubid::CenCenelec.parse("EN 1:1977")
      expect(id.to_mr_string).to eq("en.1.1977")
    end
  end

  describe "JIS" do
    it "preserves the series letter (lowercase)" do
      id = Pubid::Jis.parse("JIS A 0001:1999")
      expect(id.to_mr_string).to eq("jis.a-0001.1999")
    end

    it "preserves multi-level parts" do
      id = Pubid::Jis.parse("JIS B 3700-11:1996")
      expect(id.to_mr_string).to eq("jis.b-3700-11.1996")
    end

    it "preserves the type prefix and series" do
      id = Pubid::Jis.parse("JIS TR Z 8301:2019")
      expect(id.to_mr_string).to eq("jis.tr.z-8301.2019")
    end
  end

  describe "SAE" do
    it "preserves the type letter (lowercase)" do
      id = Pubid::Sae.parse("SAE J300:2019")
      expect(id.to_mr_string).to eq("sae.j.300.2019")
    end

    it "preserves multi-letter type codes (as, arp, ams)" do
      id = Pubid::Sae.parse("SAE AS5553")
      expect(id.to_mr_string).to eq("sae.as.5553")
    end
  end

  describe "ANSI" do
    it "emits publisher.number.year (code lowercased)" do
      id = Pubid::Ansi.parse("ANSI X3.4:1963")
      expect(id.to_mr_string).to eq("ansi.x3.4.1963")
    end
  end

  describe "CSA — mirrors to_s through filename-safe transform" do
    it "preserves the code and year (lowercase, `:` → `.`)" do
      id = Pubid::Csa.parse("CSA B149.1:2020")
      expect(id.to_mr_string).to eq("csa.b149.1.2020")
    end

    # The three semantic mappings (` ` → `.`, `:` → `.`, `/` → `-`) carry CSA's
    # segment structure; everything outside [a-z0-9._-] is then neutralised by
    # charset, so parentheses, commas, ampersands and plus signs — all of which
    # appear in real CSA references — cannot reach a filename.
    {
      "CAN/CSA-A123.2-03 (R2023)" => "can-csa-a123.2-03.-r2023",
      "CSA C22.2 NO. 100:14 (R2024)" => "csa.c22.2.no..100.14.-r2024",
      "CSA B149.1:25 Code, Handbook & Training Package" =>
        "csa.b149.1.25.code-.handbook.-.training.package",
      "CSA A23.1:24/CSA A23.2:24" => "csa.a23.1.24-csa.a23.2.24",
    }.each do |ref, slug|
      it "neutralises every unsafe character in #{ref}" do
        mr = Pubid::Csa.parse(ref).to_mr_string
        expect(mr).to eq(slug)
        expect(mr).to match(/\A[a-z0-9._-]+\z/)
      end
    end
  end

  describe "IDF" do
    it "emits publisher.number.year" do
      id = Pubid::Idf.parse("IDF 1:2018")
      expect(id.to_mr_string).to eq("idf.1.2018")
    end
  end

  describe "to_slug defaults and overrides" do
    it "every non-NIST flavor has to_slug == to_mr_string" do
      samples = {
        Iso: "ISO 9001:2015",
        Iec: "IEC 60050:2013",
        Ieee: "IEEE Std 802.3-2018",
        Bsi: "BS 490:1972",
        CenCenelec: "EN 1:1977",
        Jis: "JIS A 0001:1999",
        Sae: "SAE J300:2019",
        Ansi: "ANSI X3.4:1963",
        Csa: "CSA B149.1:2020",
        Idf: "IDF 1:2018",
        Oiml: "OIML R 87:2016",
        Itu: "ITU-T G.650",
        Cie: "CIE S 017/E:2011",
        Bipm: "CCTF REC 2 (2012)",
      }
      samples.each do |const, ref|
        id = Pubid.const_get(const).parse(ref)
        expect(id.to_slug).to eq(id.to_mr_string),
                               "#{const} should have to_slug == to_mr_string"
      end
    end

    it "NIST overrides to_slug to lowercase its MR" do
      id = Pubid::Nist.parse("NIST SP 800-53")
      expect(id.to_slug).to eq(id.to_mr_string.downcase)
      expect(id.to_slug).to eq("nist.sp.800-53")
    end
  end

  describe "MR strings are filename-safe (only [a-z0-9.-])" do
    # The slug must not contain `/`, `:`, `(`, `)`, `,`, or any uppercase.
    # NIST is the documented exception (its MR is fixed by the standard) —
    # but its to_slug is still safe.
    safe_slug_cases = [
      [Pubid::Iso, "ISO 9001:2015"],
      [Pubid::Iso, "ISO/IEC 17031-1:2020"],
      [Pubid::Iso, "ISO 9001:2015/Amd 1:2020"],
      [Pubid::Iso, "ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017"],
      [Pubid::Iso, "ISO 9001:2015(en,fr)"],
      [Pubid::Iso, "ISO 16634:--"],
      [Pubid::Iec, "IEC 60050:2013/AMD1:2016"],
      [Pubid::Ieee, "IEEE Std 802.3-2018/Cor 1:2019"],
      [Pubid::Jis, "JIS TR Z 8301:2019"],
      [Pubid::Sae, "SAE ARP4754A"],
      [Pubid::Ansi, "ANSI X3.4:1963"],
      [Pubid::Csa, "CSA B149.1:2020"],
      [Pubid::Oiml, "OIML R 87:2016"],
      [Pubid::Itu, "ITU-T G.650"],
      [Pubid::Cie, "CIE S 017/E:2011"],
      # BIPM values carry `/` (the MEP report code) and spaces (the SI Brochure
      # variant), both of which have to be transformed away.
      [Pubid::Bipm, "CCTF REC 2 (2012, F)"],
      [Pubid::Bipm, "Metrologia 55 1A 06007"],
      [Pubid::Bipm, "Rapport BIPM-2019/05"],
      [Pubid::Bipm, "BIPM SI Brochure Appendix 3"],
      [Pubid::Nist, "NIST SP 800-53"],
    ]
    safe_slug_cases.each do |flavor, ref|
      it "#{ref} (#{flavor}) slug matches /\\A[a-z0-9._-]+\\z/" do
        id = flavor.parse(ref)
        expect(id.to_slug).to match(/\A[a-z0-9._-]+\z/)
      end
    end
  end

  describe "round-trip through Pubid::Parsers::MrString" do
    # Each entry is [mr_string, parsed_to_s]. The parser reproduces an
    # equivalent identifier — exactly equal modulo the flavor's own
    # canonicalisation (e.g. ISO renders "AMD" rather than "Amd").
    round_trip_cases = [
      ["iso.9001.2015", "ISO 9001:2015"],
      ["iso-iec.17031-1.2020", "ISO/IEC 17031-1:2020"],
      ["iso.1234-1-2-3.2020", "ISO 1234-1-2-3:2020"],
      ["iso.tr.14627.2017", "ISO/TR 14627:2017"],
      ["iso.16634.--", "ISO 16634:--"],
      ["iso.9001.2015_amd.1.2020", "ISO 9001:2015/AMD 1:2020"],
      ["iso-iec.13818-1.2015_amd.3.2016_cor.1.2017",
       "ISO/IEC 13818-1:2015/AMD 3:2016/COR 1:2017"],
      ["iec.60050-351.2013_amd.1.2016", "IEC 60050-351:2013/AMD1:2016"],
      ["iso.9001.2015.en-fr", "ISO 9001:2015(en,fr)"],
    ]

    round_trip_cases.each do |mr, human|
      it "#{mr} parses back to #{human.inspect}" do
        parsed = Pubid::Parsers::MrString.parse(mr)
        expect(parsed.to_s).to eq(human)
      end
    end
  end

  describe "distinct identifiers never collide on to_mr_string" do
    collision_cases = [
      # Issue #142's specific complaint: IEC 60601-1-11 and IEC 60601-1-2 both
      # collapsed onto IEC.60601-1.<year>.
      [Pubid::Iec, "IEC 60601-1-11:2010", "IEC 60601-1-2:2010"],
      [Pubid::Iso, "ISO 1234-1-2-3:2020", "ISO 1234-1:2020"],
      [Pubid::Iso, "ISO 1234-1-2-3:2020", "ISO 1234-1-2:2020"],
      [Pubid::Iso, "ISO 9001:2015", "ISO 9001:2015/Amd 1:2020"],
      [Pubid::Iso, "ISO 9001:2015", "ISO 9001"],
      [Pubid::Iso, "ISO 16634:--", "ISO 16634:2020"],
      [Pubid::Iso, "ISO/TR 14627:2017", "ISO 14627:2017"],
      [Pubid::Iso, "ISO 9001:2015(en,fr)", "ISO 9001:2015(en)"],
    ]

    collision_cases.each do |flavor, a, b|
      it "#{a} and #{b} (#{flavor}) produce different MR strings" do
        id_a = flavor.parse(a)
        id_b = flavor.parse(b)
        expect(id_a.to_mr_string).not_to eq(id_b.to_mr_string)
      end
    end
  end

  describe "every registered flavor has a non-empty MR" do
    it "produces a non-empty MR for a representative id of each flavor" do
      samples = {
        Iso: "ISO 9001:2015",
        Iec: "IEC 60050:2013",
        Ieee: "IEEE Std 802.3-2018",
        Nist: "NIST SP 800-53",
        Bsi: "BS 490:1972",
        CenCenelec: "EN 1:1977",
        Jis: "JIS A 0001:1999",
        Sae: "SAE J300:2019",
        Ansi: "ANSI X3.4:1963",
        Idf: "IDF 1:2018",
        Bipm: "Metrologia 51 1 128",
      }

      samples.each do |const, ref|
        mod = Pubid.const_get(const)
        id = mod.parse(ref)
        expect(id.to_mr_string).not_to be_empty,
                                       "#{mod} produced empty MR for #{ref}"
      end
    end
  end
end
