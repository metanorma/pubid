# frozen_string_literal: true

require "spec_helper"
require "pubid/iala"

RSpec.describe "URN flavor routing" do
  describe ".detect_flavor_from_urn" do
    it "routes ISO-style URNs by namespace" do
      expect(Pubid.detect_flavor_from_urn("urn:iso:std:iso:123")).to eq("iso")
    end

    it "routes MRN URNs by assigning authority" do
      expect(Pubid.detect_flavor_from_urn("urn:mrn:iala:pub:g1199:ed1.0"))
        .to eq("iala")
    end
  end

  it "parses IALA MRN URNs through the umbrella" do
    id = Pubid.parse("urn:mrn:iala:pub:g1199:ed1.0")
    expect(id).to be_a(Pubid::Iala::Identifiers::Guideline)
    expect(id.to_s).to eq("IALA G1199 Ed 1.0")
    expect(id.to_urn).to eq("urn:mrn:iala:pub:g1199:ed1.0")
  end

  it "parses IALA human form through the umbrella" do
    expect(Pubid.parse("IALA G1199 Ed 1.0"))
      .to be_a(Pubid::Iala::Identifiers::Guideline)
  end

  it "raises for an unknown MRN authority" do
    expect { Pubid.parse("urn:mrn:unknown-org:pub:g1") }
      .to raise_error(ArgumentError, /Unknown flavor in URN: unknown-org/)
  end

  describe "Identifier.from_urn (the lutaml :urn parse side)" do
    it "parses a legacy stage-literal supplement URN" do
      # metanorma-pdfa#108: relaton-data carries DIS-literal URNs; the
      # format had a renderer but no parser, so every from_urn raised.
      id = Pubid::Iso::Identifier.from_urn("urn:iso:std:iso:32000:-2:DIS:amd:1:v1")
      expect(id.to_s).to eq("ISO/DIS 32000-2/AMD 1")
      # the legacy abbreviation URN re-canonicalizes to the RFC 5141
      # harmonized stage form (one render path; metanorma-pdfa#108)
      expect(id.to_urn).to eq("urn:iso:std:iso:32000:-2:stage-40.00:amd:1:v1")
    end

    it "parses a plain URN and round-trips it" do
      id = Pubid::Iso::Identifier.from_urn("urn:iso:std:iso:9001")
      expect(id.to_s).to eq("ISO 9001")
      expect(id.to_urn).to eq("urn:iso:std:iso:9001")
    end

    it "routes to the URN's own flavor, not the receiver's" do
      id = Pubid::Iso::Identifier.from_urn("urn:ieee:std:802.11:2012")
      expect(id.to_s).to eq("IEEE Std 802.11-2012")
    end

    it "raises for an unknown URN authority" do
      expect { Pubid::Iso::Identifier.from_urn("urn:mrn:unknown-org:pub:g1") }
        .to raise_error(Lutaml::Model::InvalidFormatError)
    end

    it "builds a guide supplement chain with the generic Supplement" do
      # the "sup" token used to resolve the Directives Supplement row,
      # whose render needs the supplement_publisher a guide chain never
      # has -- the chain crashed on render
      id = Pubid::Iso::Identifier.from_urn("urn:iso:std:iso-iec:guide:98:-3:ed-1:sup:1:2008:v1:cor:1:2009:v1")
      expect(id.to_s).to eq("ISO/IEC Guide 98-3/Suppl 1:2008/COR 1:2009")
      expect(id.base).to be_a(Pubid::Iso::Identifiers::Supplement)
      expect(id.to_urn).to eq("urn:iso:std:iso-iec:guide:98:-3:ed-1:sup:1:2008:v1:cor:1:2009:v1")
    end

    it "rejects a URN without a docnumber" do
      # RFC 5141 requires docnumber; the lenient parse built the
      # identity-free "ISO "
      expect { Pubid::Iso::Identifier.from_urn("urn:iso:std:iso") }
        .to raise_error(Pubid::Errors::UrnParseError, /missing docnumber/)
    end
  end
end
