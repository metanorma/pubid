# frozen_string_literal: true

require "spec_helper"

# The apostrophe-year catalogue convention ("P1484.20.1/D7, May 07"): the
# 2-digit draft-date year expands with the <30 pivot so the hash carries an
# unambiguous year (152 debt rows, the largest debt family).
RSpec.describe "IEEE 2-digit draft-date years" do
  subject(:klass) { Pubid::Ieee::Identifier }

  {
    "IEEE Approved Draft Std P1484.20.1/D7, May 07" =>
      "IEEE P1484.20.1/D7, May, 2007",
    "IEEE Approved Draft Std P1516.4/Dx.1, Jun 07" =>
      "IEEE Draft 1516.4/Dx.1, Jun, 2007",
    "IEEE Approved Draft Std P1661/D11, Jul 07" =>
      "IEEE Draft 1661/D11, Jul, 2007",
  }.each do |variant, canonical|
    it "renders #{canonical}" do
      expect(klass.parse(variant).to_s).to eq(canonical)
    end

    it "expands the year in the hash" do
      expect(klass.parse(variant).draft_obj.year).to eq("2007")
    end

    it "is idempotent" do
      rendered = klass.parse(variant).to_s
      expect(klass.parse(rendered).to_s).to eq(rendered)
    end
  end

  # The day reading wins: "May 07, 2008" is month + day + year, not a
  # 2-digit year — the day-bearing alternatives precede the short-year one.
  it "keeps the day reading for 'Mon DD, YYYY' spellings" do
    id = klass.parse("IEEE Draft Std P802.3/D2.0, May 07, 2008")
    expect(id.draft_obj.day).to eq("07")
    expect(id.draft_obj.year).to eq("2008")
  end
end
