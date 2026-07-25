# frozen_string_literal: true

require "spec_helper"

RSpec.describe "IEEE unapproved drafts must not render 'Std' — issue #209" do
  # IEEE staff guidance: an "unapproved draft" is not yet a standard, so the
  # "Std" token must not appear in the rendered identifier. "Draft" is kept;
  # only the "Std" suffix on the type is stripped.
  {
    "IEEE Unapproved Draft Std 802.3" => "IEEE Unapproved Draft 802.3/D1",
    "IEEE Unapproved Std 802.3" => "IEEE Unapproved 802.3",
    "IEEE Unapproved Draft Std P802.3" => "IEEE Unapproved Draft P802.3/D1",
  }.each do |input, expected|
    it "renders #{input.inspect} as #{expected.inspect}" do
      parsed = Pubid::Ieee.parse(input)
      expect(parsed.to_s).to eq(expected)
      expect(parsed.to_s).not_to match(/\bStd\b/)
    end
  end

  it "drops 'Std' but keeps the year for dated unapproved drafts" do
    parsed = Pubid::Ieee.parse("IEEE Unapproved Draft Std 802.3-2018")
    expect(parsed.to_s).to include("2018")
    expect(parsed.to_s).not_to match(/\bStd\b/)
  end

  it "still renders 'Std' for approved standards" do
    parsed = Pubid::Ieee.parse("IEEE Std 802.3-2018")
    expect(parsed.to_s).to eq("IEEE Std 802.3-2018")
  end

  it "still renders 'Draft Std' for non-unapproved drafts" do
    parsed = Pubid::Ieee.parse("IEEE Draft Std 802.3")
    expect(parsed.to_s).to eq("IEEE Draft Std 802.3/D1")
  end
end
