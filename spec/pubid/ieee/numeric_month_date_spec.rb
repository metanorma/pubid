# frozen_string_literal: true

require "spec_helper"

# Trailing numeric-month date "<number>, MM YYYY" (e.g. "IEEE P15026.1, 05
# 2014"). pubid accepted only the month-name form ("May 2014"); the month-first
# form failed, skipping 13 relaton-data-ieee index-v2 docids. The numeric month
# is stored verbatim (matching the existing text-month convention) and rendered
# back as ", MM YYYY".
RSpec.describe "IEEE trailing numeric-month date" do
  # The full corpus of skipped docids from the hand-off.
  corpus = [
    "IEEE P15026.1, 05 2014",
    "IEEE P15026.1, 07 2014",
    "IEEE P15026.2, 04 2011",
    "IEEE P15026.3, 03 2013",
    "IEEE P24748.1, 10 2010",
    "IEEE P24748.2, 10 2011",
    "IEEE P24748.3, 10 2011",
    "ISO/IEC/IEEE 21451.7, 04 2011",
    "ISO/IEC/IEEE 24748.3, 01 2019",
    "ISO/IEC/IEEE 24748.6, 03 2021",
    "ISO/IEC/IEEE 29119.5, 10 2023",
    "ISO/IEC/IEEE 29119.8, 03 2025",
    "ISO/IEC/IEEE 80005.1, 06 2016",
  ]

  describe "parsing every corpus form" do
    corpus.each do |ref|
      it "parses #{ref.inspect}" do
        expect { Pubid::Ieee::Identifier.parse(ref) }.not_to raise_error
      end
    end
  end

  describe "to_s round-trips the numeric form" do
    corpus.each do |ref|
      it "round-trips #{ref.inspect}" do
        expect(Pubid::Ieee::Identifier.parse(ref).to_s).to eq(ref)
      end
    end
  end

  describe "captured month/year (verbatim numeric month)" do
    it "captures a numeric month for the IEEE P form" do
      id = Pubid::Ieee::Identifier.parse("IEEE P15026.1, 05 2014")
      expect(id.month).to eq("05")
      expect(id.year).to eq("2014")
    end

    it "captures a numeric month for the ISO/IEC/IEEE form" do
      id = Pubid::Ieee::Identifier.parse("ISO/IEC/IEEE 21451.7, 04 2011")
      expect(id.month).to eq("04")
      expect(id.year).to eq("2011")
    end
  end

  describe "hash round-trips with a non-empty root.number" do
    ["IEEE P15026.1, 05 2014", "ISO/IEC/IEEE 21451.7, 04 2011"].each do |ref|
      it "round-trips the hash and keeps root.number for #{ref.inspect}" do
        id = Pubid::Ieee::Identifier.parse(ref)
        hash = id.to_hash
        expect(Pubid::Ieee::Identifier.from_hash(hash).to_hash).to eq(hash)
        expect(id.root.number.to_s).not_to be_empty
      end
    end
  end

  describe "does not disturb existing forms" do
    it "still parses the month-name form" do
      id = Pubid::Ieee::Identifier.parse("IEEE P15026.1, May 2014")
      expect(id.month).to eq("May")
      expect(id.year).to eq("2014")
      expect(id.to_s).to eq("IEEE P15026.1, May 2014")
    end

    it "does not swallow a bare 4-digit year as a numeric month" do
      # A -YYYY identity year must not be mis-read as month_numeric + year
      # (month_numeric is 01-12, a 20xx year never matches). Month stays nil.
      id = Pubid::Ieee::Identifier.parse("ISO/IEC/IEEE 21451.7-2011")
      expect(id.year).to eq("2011")
      expect(id.month).to be_nil
    end
  end
end
