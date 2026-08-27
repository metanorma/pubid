# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/pubid/ieee"

RSpec.describe "IEEE identifiers" do
  describe "simple standards" do
    it "parses IEEE Std 1234-2007" do
      parsed = Pubid::Ieee.parse("IEEE Std 1234-2007")

      expect(parsed).to be_a(Pubid::Ieee::Identifier)
      expect(parsed.publisher).to eq("IEEE")
      expect(parsed.code.number).to eq("1234")
      expect(parsed.year).to eq("2007")
      expect(parsed.to_s).to eq("IEEE Std 1234-2007")
    end

    it "parses IEEE No 264-1968" do
      parsed = Pubid::Ieee.parse("IEEE No 264-1968")

      expect(parsed.code.number).to eq("264")
      expect(parsed.year).to eq("1968")
    end

    it "parses AIEE No 1B-1944" do
      parsed = Pubid::Ieee.parse("AIEE No 1B-1944")

      expect(parsed.publisher).to eq("AIEE")
      expect(parsed.code.number).to eq("1B")
      expect(parsed.year).to eq("1944")
    end
  end

  describe "standards with parts" do
    it "parses IEEE Std 802.3-2018" do
      parsed = Pubid::Ieee.parse("IEEE Std 802.3-2018")

      expect(parsed.code.number).to eq("802")
      expect(parsed.code.parts).to eq(["3"])
      expect(parsed.year).to eq("2018")
      expect(parsed.to_s).to eq("IEEE Std 802.3-2018")
    end

    it "parses IEEE Std 802.15.4-2020" do
      parsed = Pubid::Ieee.parse("IEEE Std 802.15.4-2020")

      expect(parsed.code.number).to eq("802")
      expect(parsed.code.parts).to eq(["15", "4"])
      expect(parsed.year).to eq("2020")
    end

    it "parses IEEE Std C57.12.00-2015" do
      parsed = Pubid::Ieee.parse("IEEE Std C57.12.00-2015")

      expect(parsed.code.prefix).to eq("C")
      expect(parsed.code.number).to eq("57")
      expect(parsed.code.parts).to eq(["12", "00"])
      expect(parsed.year).to eq("2015")
    end
  end

  describe "draft standards" do
    it "parses IEEE P1234/D5, July 2019" do
      parsed = Pubid::Ieee.parse("IEEE P1234/D5, July 2019")

      # Should be a ProjectDraftIdentifier, not a StandardIdentifier
      expect(parsed).to be_a(Pubid::Ieee::Identifiers::ProjectDraftIdentifier)

      # "P" is a project/draft stage indicator, NOT a code prefix
      expect(parsed.code.prefix).to be_nil
      expect(parsed.code.number).to eq("1234")
      expect(parsed.draft).to be_a(Pubid::Ieee::Components::Draft)
      expect(parsed.draft.version).to eq("5")
      expect(parsed.draft.month).to eq("7")
      expect(parsed.draft.year).to eq("2019")
    end

    it "parses IEEE Unapproved Draft Std P1234/D5, July 2019" do
      parsed = Pubid::Ieee.parse("IEEE Unapproved Draft Std P1234/D5, July 2019")

      expect(parsed.draft_status).to eq("Unapproved")
      expect(parsed.type).to eq("Draft Std")
      expect(parsed.draft.version).to eq("5")
    end
  end
end
