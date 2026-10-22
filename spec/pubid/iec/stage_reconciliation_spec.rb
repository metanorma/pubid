# frozen_string_literal: true

require "spec_helper"

# The reconciliation round (pubid#576): every row of IEC's own
# correspondence table — committed as the SSOT at
# data/iec/stage-codes.md — resolves as a stage abbreviation or a
# harmonized-code lookup, including the per-deliverable project stages.
# Lookups only: nothing parses or renders differently.
RSpec.describe Pubid::Iec do
  # The correspondence table's (code, harmonized) pairs, verbatim from
  # the SSOT extract. CAN and DEL legitimately carry two codes each.
  SSOT_ROWS = {
    "ACD" => "20.99", "ACDV" => "30.99", "ADTR" => "40.99",
    "ADTS" => "40.99", "AFDIS" => "40.99", "APUB" => "50.99",
    "BPUB" => "60.00", "CAN" => "30.98", "CCDV" => "40.20",
    "CD" => "30.20", "CDISH" => "50.20", "CDM" => "30.60",
    "CDPAS" => "50.20", "CDTR" => "50.20", "CDTS" => "50.20",
    "CDVM" => "40.91", "CFDIS" => "50.20", "DECDISH" => "50.00",
    "DECFDIS" => "50.00", "DECPUB" => "60.00", "DEL" => "10.98",
    "DELPUB" => "99.60", "DTRM" => "50.92", "DTSM" => "50.92",
    "MERGED" => "30.97", "NCDV" => "40.91", "NDTR" => "50.92",
    "NDTS" => "50.92", "NFDIS" => "50.92", "PCC" => "30.60",
    "PNW" => "10.20", "PPUB" => "60.60", "PRVC" => "40.60",
    "PRVD" => "50.60", "PRVDISH" => "50.60", "PRVDPAS" => "50.60",
    "PRVDTR" => "50.60", "PRVDTS" => "50.60", "PRVN" => "10.60",
    "PWI" => "00.00", "RDISH" => "50.00", "RFDIS" => "50.00",
    "RPUB" => "60.00", "SPLIT" => "30.96", "TCDV" => "40.00",
    "TDISH" => "50.00", "TDTR" => "50.00", "TDTS" => "50.00",
    "TPUB" => "60.00", "WPUB" => "95.99",
  }.freeze

  it "resolves every abbreviation in IEC's correspondence table" do
    SSOT_ROWS.each_key do |abbr|
      expect(described_class.locate_stage(abbr)).not_to be_nil,
        "#{abbr} does not resolve"
    end
  end

  it "records the abbreviations carrying two harmonized codes" do
    # CAN: 30.98 for IS/TR/TS drafts, 50.98 for PAS/ISH/COR.
    # DEL: 10.98 for IS/TR/TS, 20.98 for ISH.
    # The codes are claimed by the ladder stages; the abbreviation
    # resolves to the stage claiming its first code.
    expect(described_class.locate_stage("CAN")).not_to be_nil
    expect(described_class.locate_stage("DEL").code.to_s).to eq("np")
    expect(described_class.locate_stage_by_harmonized_code("30.98").code.to_s)
      .to eq("cd")
    expect(described_class.locate_stage_by_harmonized_code("50.98").code.to_s)
      .to eq("fdis")
  end

  it "maps the harmonized codes that only this round claimed" do
    expect(described_class.locate_stage_by_harmonized_code("99.60").code.to_s)
      .to eq("is")
    expect(described_class.locate_stage_by_harmonized_code("30.96").code.to_s)
      .to eq("cd")
    expect(described_class.locate_stage_by_harmonized_code("30.97").code.to_s)
      .to eq("cd")
    # A shared code resolves to the IS family deterministically
    # (pubid#570's rule) — 40.99 belongs to cdv (IS) whatever the
    # registry's load order.
    expect(described_class.locate_stage_by_harmonized_code("40.99").code.to_s)
      .to eq("cdv")
  end

  it "makes the per-deliverable project stages queryable" do
    %w[AFDIS TCDV PRVC PRVD DECFDIS CCDV CDVM NCDV NFDIS CFDIS
       ADTR CDTR DTRM NDTR TDTR PRVDTR
       ADTS CDTS DTSM NDTS TDTS PRVDTS
       DECDISH PRVDISH RDISH TDISH PRVDPAS].each do |abbr|
      expect(described_class.locate_stage(abbr)).not_to be_nil,
        "#{abbr} does not resolve"
    end
  end

  # The review/withdrawal ladder rows (90.xx/95.xx) stay: #237's own
  # STAGE_CODES maps RR to 9092, and the harmonized system is joint
  # ISO/IEC — IEC's correspondence table simply does not name IEC
  # stage codes for the review sub-states.
  it "keeps the harmonized review ladder claimed" do
    expect(described_class.locate_stage("RR")).not_to be_nil
    expect(described_class.locate_stage_by_harmonized_code("90.92")).not_to be_nil
  end

  it "keeps the canonical abbreviations first" do
    expect(described_class.locate_stage("ANW").abbr.first).to eq("ANW")
    expect(described_class.locate_stage("NP").abbr.first).to eq("NP")
    expect(described_class.locate_stage("WD").abbr.first).to eq("WD")
    expect(described_class.locate_stage("AFDIS").abbr.first).to eq("AFDIS")
  end

  it "does not resolve a code outside the ladder" do
    expect(described_class.locate_stage("99.99")).to be_nil
  end
end
