# frozen_string_literal: true

require "spec_helper"

# pubid#237: consumers query IEC by stage abbreviation. The issue's list
# is metanorma-iec's STAGE_CODES table (55 entries), quoted verbatim in
# the issue body — every entry must resolve. The IEC sources for them
# are the stage tables (pubid-iec/stages.yaml, pubid-iso/stages.yaml)
# and IEC's own Data-Feeds-successor documents, extracted in
# data/iec/stage-codes.md.
RSpec.describe Pubid::Iec do
  # The issue's STAGE_CODES, in the issue's own order.
  ISSUE_ABBREVIATIONS = %w[
    PNW ANW CAN ACD CD BWG A2CD 2CD 3CD 4CD 5CD 6CD 7CD 8CD 9CD CDM
    A3CD A4CD A5CD A6CD A7CD A8CD A9CD ACDV CCDV CDVM NCDV
    NADIS ADIS ADTR ADTS RDISH RFDIS CDISH CDPAS CDTR CDTS CFDIS
    DTRM DTSM NDTR NDTS NFDIS APUB BPUB PPUB RR AMW WPUB DELPUB
    PWI NWIP WD CDV FDIS
  ].freeze

  it "resolves every abbreviation in the issue's list" do
    ISSUE_ABBREVIATIONS.each do |abbr|
      expect(described_class.locate_stage(abbr)).not_to be_nil,
        "#{abbr} does not resolve"
    end
  end

  # Abbreviations registered from other sources than the issue's list:
  # AWI is the ISO table's abbreviation for 20.00/10.99 (the ANW stage),
  # DIS names the 40.00/40.20 stages (both tables' descriptions), and
  # ADIS is the legacy Data Feeds spelling of AFDIS at 40.99
  # (data/iec/stage-codes.md) — cdv is the typed stage claiming 40.99.
  it "maps the table-sourced aliases to their harmonized stages" do
    expect(described_class.locate_stage("AWI").code.to_s).to eq("anw")
    expect(described_class.locate_stage("DIS").code.to_s).to eq("cdv")
    expect(described_class.locate_stage("ADIS").code.to_s).to eq("cdv")
  end

  it "keeps the canonical abbreviation first, so renders are unchanged" do
    expect(described_class.locate_stage("ANW").abbr.first).to eq("ANW")
    expect(described_class.locate_stage("CDV").abbr.first).to eq("CDV")
    expect(described_class.locate_stage("DISH").abbr.first).to eq("DISH")
    expect(described_class.locate_stage("DPAS").abbr.first).to eq("DPAS")
  end

  it "does not resolve a code outside the ladder" do
    expect(described_class.locate_stage("99.99")).to be_nil
  end
end
