# frozen_string_literal: true

require "spec_helper"

RSpec.describe "IEEE default draft version — issue #205" do
  describe "Draft type without explicit version" do
    it "appends /D1 to 'IEEE Unapproved Draft Std 802.3'" do
      parsed = Pubid::Ieee.parse("IEEE Unapproved Draft Std 802.3")
      # Per IEEE guidance (issue #209), unapproved drafts are not yet standards,
      # so the "Std" token is dropped from the rendered type.
      expect(parsed.to_s).to eq("IEEE Unapproved Draft 802.3/D1")
    end

    it "appends /D1 to 'IEEE Draft Std 802.3'" do
      parsed = Pubid::Ieee.parse("IEEE Draft Std 802.3")
      expect(parsed.to_s).to eq("IEEE Draft Std 802.3/D1")
    end

    it "preserves the year as part of the draft suffix" do
      parsed = Pubid::Ieee.parse("IEEE Unapproved Draft Std 802.3-2018")
      expect(parsed.to_s).to include("/D1")
      expect(parsed.to_s).to include("2018")
    end
  end

  describe "non-Draft types are unaffected" do
    it "leaves 'IEEE Std 802.3' without a draft suffix" do
      parsed = Pubid::Ieee.parse("IEEE Std 802.3")
      expect(parsed.to_s).to eq("IEEE Std 802.3")
    end
  end

  describe "explicit draft versions are preserved" do
    it "keeps /D2 when present" do
      parsed = Pubid::Ieee.parse("IEEE Unapproved Draft Std 802.3/D2")
      expect(parsed.draft_obj.version).to eq("2")
    end
  end
end
