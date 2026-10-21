# frozen_string_literal: true

require "spec_helper"

# pubid#237: consumers query IEC by stage abbreviation. Every
# abbreviation in the issue's list must resolve, except the three that
# appear in NEITHER authoritative stage table
# (pubid-iec/stages.yaml, pubid-iso/stages.yaml) — those stay nil so a
# source for them trips this spec instead of being guessed.
RSpec.describe Pubid::Iec do
  ISSUE_ABBREVIATIONS = %w[
    PWI NWIP AWG AMW BPUB PPUB APUB WPUB DELPUB RR NFDIS NDTR NDTS BWG NP
    AWI AWIN CD ACD 2CD 3CD 4CD 5CD 6CD 7CD 8CD 9CD
    A2CD A3CD A4CD A5CD A6CD A7CD A8CD A9CD
    CDV ACDV CCDV NCDV DIS ADIS ADTR ADTS CAN NADIS RDISH RFDIS
    CDTR CDTS CFDIS DTS DTSM DTR DTRM FDIS PUB
  ].freeze

  # Absent from pubid-iec/stages.yaml and pubid-iso/stages.yaml alike.
  NOT_IN_TABLES = %w[AWG ADIS CANV].freeze

  it "resolves every abbreviation sourced from the stage tables" do
    (ISSUE_ABBREVIATIONS - NOT_IN_TABLES).each do |abbr|
      expect(described_class.locate_stage(abbr)).not_to be_nil,
        "#{abbr} does not resolve"
    end
  end

  it "leaves the abbreviations no table defines unregistered" do
    NOT_IN_TABLES.each do |abbr|
      expect(described_class.locate_stage(abbr)).to be_nil,
        "#{abbr} now resolves — record its source and harmonized codes"
    end
  end

  # The aliases added from the stage tables, mapped by their codes:
  # AWI is the ISO table's abbreviation for 20.00/10.99 (the ANW stage),
  # DIS names the 40.00/40.20 stages (both tables' descriptions), and PUB
  # is the publication stage 60.00/60.60 (the *PUB compounds point there).
  it "maps the table-sourced aliases to their harmonized stages" do
    expect(described_class.locate_stage("AWI").code.to_s).to eq("anw")
    expect(described_class.locate_stage("DIS").code.to_s).to eq("cdv")
    expect(described_class.locate_stage("PUB").code.to_s).to eq("is")
  end

  it "keeps the canonical abbreviation first, so renders are unchanged" do
    expect(described_class.locate_stage("ANW").abbr.first).to eq("ANW")
    expect(described_class.locate_stage("CDV").abbr.first).to eq("CDV")
  end

  it "does not resolve a code outside the ladder" do
    expect(described_class.locate_stage("99.99")).to be_nil
  end
end
