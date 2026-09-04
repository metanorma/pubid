# frozen_string_literal: true

require "spec_helper"

# A JCGM meeting carries its year in a trailing " (YYYY)" group, e.g.
# "JCGM 11st Meeting (2006)". The year is optional: JCGM numbers its meetings in
# one sequence, so the ordinal alone identifies the event. The bare form is what
# relaton's `remove_date!` produces through
# `Bib::ItemData#to_most_recent_reference`.
RSpec.describe "JCGM meeting partial reference parsing" do
  describe "JCGM 11st Meeting" do
    subject(:id) { Pubid::Jcgm.parse("JCGM 11st Meeting") }

    it "parses as a Meeting" do
      expect(id).to be_a(Pubid::Jcgm::Identifiers::Meeting)
    end

    it "parses with date left nil" do
      expect(id.date).to be_nil
    end

    it "keeps the ordinal" do
      expect(id.number).to eq("11")
    end

    it "round-trips through to_s" do
      expect(id.to_s).to eq("JCGM 11st Meeting")
    end

    it "round-trips through to_hash/from_hash" do
      hash = id.to_hash
      expect(hash).to eq("_type" => "pubid:jcgm:meeting", "number" => "11")
      expect(Pubid::Jcgm::Identifier.from_hash(hash).to_hash).to eq(hash)
    end

    # UrnGenerator already guarded the date and emitted the short URN; the
    # UrnParser rebuilt "JCGM 11st Meeting ()" from it, which does not parse.
    it "round-trips through the URN" do
      expect(id.to_urn).to eq("urn:jcgm:meeting:11")
      expect(Pubid.parse(id.to_urn).to_s).to eq("JCGM 11st Meeting")
    end
  end

  # The acceptance path from the hand-off: relaton clears the date in place and
  # re-renders, so a dated meeting must render its bare form after the mutation.
  describe "clearing the date on a parsed meeting" do
    subject(:id) { Pubid::Jcgm.parse("JCGM 11st Meeting (2006)") }

    it "renders the dateless form instead of raising" do
      id.date = nil
      expect(id.to_s).to eq("JCGM 11st Meeting")
    end

    it "re-parses what it rendered" do
      id.date = nil
      expect(Pubid::Jcgm.parse(id.to_s)).to eq(id)
    end
  end

  describe "#matches? with the date ignored" do
    let(:partial) { Pubid::Jcgm.parse("JCGM 11st Meeting") }
    let(:full)    { Pubid::Jcgm.parse("JCGM 11st Meeting (2006)") }
    let(:other)   { Pubid::Jcgm.parse("JCGM 12nd Meeting (2007)") }

    it "matches the same meeting when ignoring the date" do
      expect(partial.matches?(full, ignore: [:date])).to be true
    end

    it "does not match a different meeting" do
      expect(partial.matches?(other, ignore: [:date])).to be false
    end
  end

  # Only the whole " (YYYY)" group is optional. A dangling parenthesis or a
  # truncated year must still fail (JCGM has no fail/ fixture corpus).
  describe "malformed dateless meetings still fail" do
    [
      "JCGM 11st Meeting (",
      "JCGM 11st Meeting ()",
      "JCGM 11st Meeting (200)",
      "JCGM 11st Meeting (2006",
      "JCGM 11st Meeting 2006",
      "JCGM 11 Meeting",
    ].each do |ref|
      it "rejects #{ref.inspect}" do
        expect { Pubid::Jcgm.parse(ref) }.to raise_error(StandardError)
      end
    end
  end

  # The published meeting records must keep their verbatim round-trip,
  # including the naive ordinal rule (no English teens exception).
  describe "published meeting records are unaffected" do
    [
      "JCGM 11st Meeting (2006)",
      "JCGM 12nd Meeting (2007)",
      "JCGM 13rd Meeting (2008)",
      "JCGM 17th Meeting (2012)",
      "JCGM 21st Meeting (2017)",
    ].each do |ref|
      it "round-trips #{ref.inspect} verbatim" do
        id = Pubid::Jcgm.parse(ref)
        expect(id.to_s).to eq(ref)
        expect(id.date).not_to be_nil
        expect(Pubid::Jcgm::Identifier.from_hash(id.to_hash).to_hash)
          .to eq(id.to_hash)
      end
    end
  end
end
