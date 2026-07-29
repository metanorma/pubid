# frozen_string_literal: true

require "spec_helper"
require "pubid/gost"
require "pubid/iso"

RSpec.describe "Pubid::Gost#exclude / #matches? year wildcard" do
  describe "#exclude(:year)" do
    it "drops the year for a national standard (GOST R)" do
      id = Pubid::Gost.parse("GOST R 34.12-2015")
      expect(id.exclude(:year).to_s).to eq("GOST R 34.12")
    end

    it "drops the year for an interstate standard (bare GOST)" do
      id = Pubid::Gost.parse("GOST 14946-82")
      expect(id.exclude(:year).to_s).to eq("GOST 14946")
    end

    it "leaves an already year-less identifier unchanged" do
      id = Pubid::Gost.parse("GOST R 34.12")
      expect(id.exclude(:year).to_s).to eq("GOST R 34.12")
    end
  end

  describe "#matches?(other, ignore: [:year])" do
    it "matches an undated reference against any edition" do
      undated = Pubid::Gost.parse("GOST R 34.12")
      %w[GOST\ R\ 34.12-2015 GOST\ R\ 34.12-2018].each do |dated|
        expect(undated.matches?(Pubid::Gost.parse(dated), ignore: [:year]))
          .to be true
      end
    end

    it "still distinguishes national from interstate subtypes" do
      national = Pubid::Gost.parse("GOST R 34.12")
      interstate = Pubid::Gost.parse("GOST 34.12-2015")
      expect(national.matches?(interstate, ignore: [:year])).to be false
    end

    it "still distinguishes different numbers" do
      one_one = Pubid::Gost.parse("GOST 1.1")
      one_ten = Pubid::Gost.parse("GOST 1.10")
      expect(one_one.matches?(one_ten, ignore: [:year])).to be false
    end
  end

  describe "#matches? exact (no ignore)" do
    it "matches an identical dated identifier" do
      a = Pubid::Gost.parse("GOST R 34.12-2015")
      expect(a.matches?(Pubid::Gost.parse("GOST R 34.12-2015"))).to be true
    end

    it "does not match a different edition" do
      a = Pubid::Gost.parse("GOST R 34.12-2015")
      expect(a.matches?(Pubid::Gost.parse("GOST R 34.12-2018"))).to be false
    end
  end

  describe "regression: year-in-date flavors (ISO)" do
    it "still round-trips exclude(:year)" do
      iso = Pubid::Iso.parse("ISO 216:2007")
      expect(iso.exclude(:year).to_s).to eq("ISO 216")
    end
  end
end
