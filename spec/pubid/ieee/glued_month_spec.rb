# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Glued identity year-month (pubid#517)" do
  # "ANSI/IEEE 21-1976-11" (NESC Outdoor Apparatus Bushings) and
  # "IEEE Std PC2-2016-01" (NESC draft) parse through the grammar's
  # date_with_month_numeric — the same :month/:year attributes as the
  # trailing ", 05 2014" print date, so the distinction is provenance.
  # The renderer must reproduce the glued face, not the comma form.

  it "round-trips the NESC glued designation" do
    expect(Pubid::Ieee::Identifier.parse("ANSI/IEEE 21-1976-11").to_s)
      .to eq("ANSI/IEEE 21-1976-11")
  end

  it "round-trips the glued draft designation" do
    expect(Pubid::Ieee::Identifier.parse("IEEE Std PC2-2016-01").to_s)
      .to eq("IEEE Std PC2-2016-01")
  end

  it "carries the glued month through to_hash/from_hash" do
    id = Pubid::Ieee::Identifier.parse("ANSI/IEEE 21-1976-11")
    expect(id.month_glued).to be(true)
    round = Pubid::Ieee::Identifier.from_hash(id.to_hash)
    expect(round.month_glued).to be(true)
    expect(round.to_s).to eq("ANSI/IEEE 21-1976-11")
  end

  # The comma face is the LONG format only (a month name); a numeric
  # month renders the short glued face whatever the input spelling
  # (pubid#517 ruling). The provenance flag still records how the
  # month arrived.
  it "renders the numeric print date in the short glued format" do
    id = Pubid::Ieee::Identifier.parse("IEEE P15026.1, 05 2014")
    expect(id.month_glued).to be(false)
    expect(id.to_s).to eq("IEEE P15026.1-2014-05")
  end

  it "keeps the year-on-code render for a glued month with draft" do
    expect(Pubid::Ieee::Identifier.parse("IEEE Std PC2-2016-01").year)
      .to eq("2016")
  end
end
