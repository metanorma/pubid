# frozen_string_literal: true

require "spec_helper"

# The joint catalogue's dash/underscore stage tails carry a month-name
# date ("IEEE/ISO/IEC P29119-2-DIS, December 2011"). The generic route
# used to claim them and answer with a slashed copublisher, so the alias
# and its D= canonical were different identities.
RSpec.describe "IEEE joint dash/underscore stage aliases" do
  describe "the IEEE-led joint list" do
    it "re-spells the dash stage as the D= designator" do
      id = Pubid::Ieee::Identifier.parse(
        "IEEE/ISO/IEC P29119-2-DIS, December 2011",
      )
      expect(id.to_s).to eq("IEEE/ISO/IEC P29119-2/D=DIS-201112")
    end

    it "re-spells the underscore stage" do
      id = Pubid::Ieee::Identifier.parse(
        "IEEE/ISO/IEC P29119-4_FDIS, December 2020",
      )
      expect(id.to_s).to eq("IEEE/ISO/IEC P29119-4/D=FDIS-202012")
    end

    it "keeps a stage iteration" do
      id = Pubid::Ieee::Identifier.parse(
        "IEEE/ISO/IEC P29119-3-DIS2, September 2012",
      )
      expect(id.to_s).to eq("IEEE/ISO/IEC P29119-3/D=DIS2-201209")
    end

    it "re-spells the reordered IEEE/IEC/ISO list" do
      id = Pubid::Ieee::Identifier.parse(
        "IEEE/IEC/ISO P29119-2-DIS, December 2011",
      )
      expect(id.to_s).to eq("IEEE/IEC/ISO P29119-2/D=DIS-201112")
    end
  end

  describe "identity convergence" do
    [
      ["IEEE/ISO/IEC P29119-2-DIS, December 2011",
       "IEEE/ISO/IEC P29119-2/D=DIS-201112"],
      ["IEEE/ISO/IEC P29119-4_FDIS, December 2020",
       "IEEE/ISO/IEC P29119-4/D=FDIS-202012"],
    ].each do |spelling, canonical|
      it "parses #{spelling.inspect} as its canonical identity" do
        alias_id = Pubid::Ieee::Identifier.parse(spelling)
        canonical_id = Pubid::Ieee::Identifier.parse(canonical)
        expect(alias_id.to_hash).to eq(canonical_id.to_hash)
        expect(
          Pubid::Ieee::Identifier.from_hash(alias_id.to_hash).to_hash,
        ).to eq(alias_id.to_hash)
      end
    end
  end

  describe "the stage-first with-part spellings" do
    it "renders the dot face from a dash-joined stage" do
      expect(
        Pubid::Ieee::Identifier.parse("ISO/IEC/IEEE P15288-DIS-1403").to_s,
      ).to eq("ISO/IEC/IEEE DIS P15288.1403")
    end

    it "keeps the trailing month-name date" do
      expect(
        Pubid::Ieee::Identifier.parse(
          "ISO/IEC/IEEE P12207-FDIS-1707, June 2017",
        ).to_s,
      ).to eq("ISO/IEC/IEEE FDIS P12207.1707, June 2017")
    end
  end
end
