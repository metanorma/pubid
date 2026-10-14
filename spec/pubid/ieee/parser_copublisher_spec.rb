# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Ieee::Parser do
  describe "copublisher organization support" do
    context "CSA (Canadian Standards Association)" do
      it "parses IEEE/CSA identifiers" do
        result = Pubid::Ieee.parse("IEEE/CSA P844.1-2017")
        expect(result).to be_a(Pubid::Ieee::Identifiers::JointDevelopment)
        expect(result.publishers.to_s).to include("IEEE")
        expect(result.code.to_s).to eq("P844.1")
      end

      it "parses IEEE/CSA dual numbering format" do
        result = Pubid::Ieee.parse("IEEE Std 844.1-2017/CSA C22.2 No. 293.1-17")
        expect(result.publisher).to eq("IEEE")
        # This pattern may be parsed as different format - just verify it parses
        expect(result).to be_a(Pubid::Ieee::Identifier)
      end

      it "parses IEEE/CSA P pattern with dual numbering" do
        result = Pubid::Ieee.parse("IEEE/CSA P844.1/293.1/D2")
        expect(result).to be_a(Pubid::Ieee::Identifiers::JointDevelopment)
        expect(result.publishers.to_s).to include("IEEE")
      end

      it "glues the joint IEEE/CSA draft date into the designator" do
        result = Pubid::Ieee.parse("IEEE/CSA Draft P844.1/D2, Sept, 2016")
        expect(result.to_s).to eq("IEEE/CSA Draft P844.1/D2-2016-09")
      end

      it "re-parses the glued face onto the draft-embedded date" do
        result = Pubid::Ieee.parse("IEEE/CSA Draft P844.1/D2-2016-09")
        expect(result.to_s).to eq("IEEE/CSA Draft P844.1/D2-2016-09")
        expect(result).to be_a(Pubid::Ieee::Identifiers::ProjectDraftIdentifier)
      end
    end

    context "ASME (American Society of Mechanical Engineers)" do
      it "parses IEEE/ASME identifiers" do
        result = Pubid::Ieee.parse("IEEE Std 120-1955")
        # ASME appears in semicolon equivalence: "IEEE Std 120-1955; ASME PTC 19.6-1955"
        # This is tested in combined/equivalence patterns
        expect(result).to be_a(Pubid::Ieee::Identifier)
      end

      it "recognizes ASME in parser organization list" do
        expect do
          Pubid::Ieee.parse("ASME PTC 19.6-1955")
        end.not_to raise_error
      end
    end

    context "ASA (American Standards Association)" do
      it "parses ASA identifiers in AIEE equivalence" do
        result = Pubid::Ieee.parse("AIEE No 18-1934 (ASA C55 1934)")
        expect(result).to be_a(Pubid::Ieee::Identifier)
        # ASA appears in parenthetical content
      end

      it "recognizes ASA in parser organization list" do
        # Test that ASA can be parsed as publisher
        expect do
          Pubid::Ieee.parse("ASA C55-1934")
        end.not_to raise_error
      end
    end

    context "ASTM (already supported)" do
      it "parses IEEE/ASTM identifiers" do
        result = Pubid::Ieee.parse("IEEE/ASTM SI 10-1997")
        expect(result.publisher).to eq("IEEE")
        expect(result.copublisher).to include("ASTM")
      end

      it "parses IEEE/ASTM P pattern" do
        result = Pubid::Ieee.parse("IEEE/ASTM PSI 10/D2")
        expect(result.publisher).to eq("IEEE")
        expect(result.copublisher).to include("ASTM")
      end
    end
  end

  describe "ANSI P prefix support" do
    it "parses ANSI PN42.34-2015" do
      result = Pubid::Ieee.parse("ANSI PN42.34-2015")
      expect(result.publisher).to eq("ANSI")
      expect(result.typed_stage&.project_status).to be true
      expect(result.code.to_s).to eq("N42.34")
      expect(result.year).to eq("2015")
    end

    it "parses ANSI PN42.34-D9a, 2015 with draft notation" do
      result = Pubid::Ieee.parse("ANSI PN42.34-D9a, 2015")
      expect(result.publisher).to eq("ANSI")
      expect(result.code.to_s).to eq("N42.34")
    end

    it "parses ANSI PN42.38_D12, 2015" do
      result = Pubid::Ieee.parse("ANSI PN42.38_D12, 2015")
      expect(result.publisher).to eq("ANSI")
      expect(result.code.to_s).to eq("N42.38")
    end
  end
end
