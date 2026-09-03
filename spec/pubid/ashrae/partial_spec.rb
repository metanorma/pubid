# frozen_string_literal: true

require "spec_helper"

RSpec.describe "ASHRAE partial reference parsing" do
  # Bare references that omit the publication year. relaton needs these to parse
  # (with year left nil) so it can match catalogue rows by excluding the year.
  # The bare form has no type keyword, so it canonicalizes to the default
  # "Standard" type on render (relaton matches on the code, not the type word).
  partial_refs = {
    "ASHRAE 15" => "ASHRAE Standard 15",
    "ASHRAE 90.1" => "ASHRAE Standard 90.1",
  }

  partial_refs.each do |ref, canonical|
    describe ref.inspect do
      subject(:id) { Pubid::Ashrae.parse(ref) }

      it "parses with year left nil" do
        expect(id.year).to be_nil
      end

      it "canonicalizes to the Standard form" do
        expect(id.to_s).to eq(canonical)
      end

      it "round-trips through to_hash/from_hash" do
        hash = id.to_hash
        expect(Pubid::Ashrae::Identifier.from_hash(hash).to_hash).to eq(hash)
      end
    end
  end

  describe "the mis-route fix for ASHRAE <code>-<year>" do
    subject(:id) { Pubid::Ashrae.parse("ASHRAE 15-2019") }

    it "parses the code correctly" do
      expect(id.number).to eq("15")
    end

    it "parses the year correctly" do
      expect(id.year).to eq("2019")
    end

    it "renders the full standard form" do
      expect(id.to_s).to eq("ASHRAE Standard 15-2019")
    end
  end

  describe "#matches? with the year ignored" do
    let(:partial) { Pubid::Ashrae.parse("ASHRAE 15") }
    let(:full)    { Pubid::Ashrae.parse("ASHRAE 15-2019") }
    let(:other)   { Pubid::Ashrae.parse("ASHRAE 90.1-2019") }

    it "matches a full id of the same document when ignoring the year" do
      expect(partial.matches?(full, ignore: [:year])).to be true
    end

    it "does not match a different document" do
      expect(partial.matches?(other, ignore: [:year])).to be false
    end
  end

  describe "#matches? on a wrapper type with the year ignored" do
    # The year of an Addendum lives in its nested `base`; the exclude override
    # reaches it through the base recursion, not the wrapper's own scalar.
    let(:partial) { Pubid::Ashrae.parse("ASHRAE Addendum a to Standard 15") }
    let(:full)    { Pubid::Ashrae.parse("ASHRAE Addendum a to Standard 15-2019") }
    let(:other)   { Pubid::Ashrae.parse("ASHRAE Addendum b to Standard 15-2019") }

    it "leaves the nested base year nil on the partial" do
      expect(partial.base.year).to be_nil
    end

    it "matches the same addendum of a dated base when ignoring the year" do
      expect(partial.matches?(full, ignore: [:year])).to be true
    end

    it "does not match a different addendum" do
      expect(partial.matches?(other, ignore: [:year])).to be false
    end
  end

  describe "full ids are unaffected" do
    subject(:id) { Pubid::Ashrae.parse("ASHRAE Standard 15-2019") }

    it "still carries the year" do
      expect(id.year).to eq("2019")
    end

    it "round-trips to_s unchanged" do
      expect(id.to_s).to eq("ASHRAE Standard 15-2019")
    end
  end
end
