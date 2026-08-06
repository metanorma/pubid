# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/urn_round_trip"

RSpec.describe "Pubid::Bipm URN" do
  it_behaves_like "flavor URN round-trip", Pubid::Bipm, [
    "CCTF REC 2 (2012)",
    "CGPM DECL (1889)",
    "JCRB ACT 10-1 (2003)",
    "CGPM 17th Meeting (1983)",
    "CIPM 100-1th Meeting (2011)",
    "Metrologia 51 1 128",
    "Metrologia 1",
    "BIPM SI Brochure 9e v3.01 (2019/2024, E)",
    "BIPM SI Brochure sur le SI 9e v3.01 (2019/2024, F)",
    "CIPM 2005-06",
  ]

  describe "#to_urn" do
    it "emits the urn:bipm namespace per family" do
      expect(Pubid::Bipm.parse("CCTF REC 2 (2012)").to_urn)
        .to eq("urn:bipm:cctf:rec:2:2012")
      expect(Pubid::Bipm.parse("CGPM 17th Meeting (1983)").to_urn)
        .to eq("urn:bipm:cgpm:meeting:17:1983")
      expect(Pubid::Bipm.parse("Metrologia 51 1 128").to_urn)
        .to eq("urn:bipm:metrologia:51:1:128")
    end

    it "uses an empty number segment for number-less committee docs" do
      expect(Pubid::Bipm.parse("CGPM DECL (1889)").to_urn)
        .to eq("urn:bipm:cgpm:decl::1889")
    end
  end

  describe "UrnParser" do
    it "reconstructs the identifier from the URN" do
      expect(Pubid::Bipm::UrnParser.parse("urn:bipm:cctf:rec:2:2012").to_s)
        .to eq("CCTF REC 2 (2012)")
      expect(Pubid::Bipm::UrnParser.parse("urn:bipm:cgpm:decl::1889").to_s)
        .to eq("CGPM DECL (1889)")
    end
  end
end
