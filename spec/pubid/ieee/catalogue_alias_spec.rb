# frozen_string_literal: true

require "spec_helper"

# Catalogue spellings the classifier records as one-round aliases of a
# canonical face: each input re-spells to the face the joint/draft route
# reads, so the alias renders its recorded human.
RSpec.describe "IEEE catalogue alias spellings" do
  describe "the stage-first joint draft's bare comma year" do
    it "drops the year and keeps the dash part" do
      id = Pubid::Ieee::Identifier.parse("IEC/IEEE FDIS P60780-323, 2015")
      expect(id.to_s).to eq("IEC/IEEE FDIS P60780.323")
      expect(id).to be_a(Pubid::Ieee::Identifiers::JointDevelopment)
    end

    it "keeps the multi-part form" do
      id = Pubid::Ieee::Identifier.parse("IEC/IEEE FDIS P60079-30-1, 2015")
      expect(id.to_s).to eq("IEC/IEEE FDIS P60079.30.1")
    end
  end

  describe "the glued WD iteration tail" do
    it "re-spells to the canonical draft face" do
      id = Pubid::Ieee::Identifier.parse("ISO/IEC/IEEE P42010.WD4:2019(E)")
      expect(id.to_s).to eq("ISO/IEC/IEEE P42010/D4, 2019")
    end
  end

  describe "the glued language marker" do
    it "re-spells on the three-way ISO-led list" do
      expect(
        Pubid::Ieee::Identifier.parse("ISO/IEC/IEEE 8802-1AC-2018(E)").to_s,
      ).to eq("ISO/IEC/IEEE 8802-1AC-2018")
    end

    it "leaves the two-way copublished glued (E) as identity" do
      expect(
        Pubid::Ieee::Identifier.parse("IEC/IEEE 62271-37-082:2012(E)").to_s,
      ).to eq("IEC/IEEE 62271-37-082:2012(E)")
    end
  end

  describe "the two-digit draft ordinal" do
    it "re-spells to the D ordinal" do
      expect(
        Pubid::Ieee::Identifier.parse("IEEE P1052/08, September 2018").to_s,
      ).to eq("IEEE P1052/D08, Sept, 2018")
    end

    it "keeps the part in the number" do
      expect(
        Pubid::Ieee::Identifier.parse("IEEE P11073-10422/04, November 2015")
          .to_s,
      ).to eq("IEEE P11073-10422/D04, Nov, 2015")
    end
  end

  describe "the revision word after the draft ordinal" do
    it "moves the revision onto the number" do
      expect(
        Pubid::Ieee::Identifier.parse(
          "IEEE PC37.30.2/D03 Rev 8, October 2013",
        ).to_s,
      ).to eq("IEEE Draft PC37.30.2Rev8/D03-2013-10")
    end
  end

  describe "the draft-stage ladder on project aliases" do
    it "takes the fabricated D1 for a date-only Draft Std" do
      expect(
        Pubid::Ieee::Identifier.parse(
          "IEEE Draft Std P754/D1.2.6 Nov 2006",
        ).to_s,
      ).to eq("IEEE P754/D1")
    end

    it "takes the stage token from a doubled-D designator" do
      expect(
        Pubid::Ieee::Identifier.parse("IEEE Draft P15288/DCD1").to_s,
      ).to eq("IEEE P15288/D=CD1")
    end

    it "takes the stage token from a bare stage-version designator" do
      expect(
        Pubid::Ieee::Identifier.parse("IEEE Draft Std P15288/CD1").to_s,
      ).to eq("IEEE P15288/D=CD1")
    end

    it "keeps the Draft word when the ordinal is not a stage" do
      expect(
        Pubid::Ieee::Identifier.parse("IEEE Draft PC95.7/D11, Mar, 2014").to_s,
      ).to eq("IEEE Draft PC95.7/D11, Mar, 2014")
    end
  end
end
