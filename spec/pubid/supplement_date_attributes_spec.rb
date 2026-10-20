# frozen_string_literal: true

require "spec_helper"

# `Pubid::Identifier#exclude` recurses into every nested identifier
# (`base`, `identifiers`, …) at unlimited depth. That is right for a
# wrapper, which owns no date of its own — the date lives on the document it
# wraps, so the exclusion has to reach through. It is wrong for a supplement
# (an Amendment/Corrigendum), which owns its own ordinal and date: a bare
# `exclude(:date)` on a consolidated identifier should drop the base
# standard's date, not the attached amendment's.
#
# CEN/CENELEC carried a per-flavor `#exclude` override to get this right;
# BSI dodged the same problem by naming the supplement's own date attribute
# `year` (a plain :string) instead of the inherited `date` component, which
# only protected it from a bare `exclude(:date)`, not `exclude(:year)`.
#
# `Identifier.supplement_date_attributes` (default `[]`, meaning "nothing
# protected, recurse as before") promotes CEN's mechanism into the base
# class, so both dodges become unnecessary.
RSpec.describe "Pubid::Identifier#exclude — supplement's own date" do
  it "does not protect anything by default" do
    expect(Pubid::Identifier.supplement_date_attributes).to eq([])
  end

  describe "CEN/CENELEC" do
    it "no longer overrides #exclude on the shared Identifier" do
      expect(Pubid::CenCenelec::Identifier.instance_method(:exclude).owner)
        .to eq(Pubid::Identifier)
    end

    it "separates the base year from the supplement's own via :supplement_year" do
      parsed = Pubid::CenCenelec.parse("EN 13250:2000/A1:2005")

      expect(parsed.exclude(:year).to_s).to eq("EN 13250/A1:2005")
      expect(parsed.exclude(:supplement_year).to_s).to eq("EN 13250:2000/A1")
      expect(parsed.exclude(:year, :supplement_year).to_s).to eq("EN 13250/A1")
    end
  end

  describe "BSI" do
    it "holds the amendment's own date in the inherited `date`" do
      expect(Pubid::Bsi::Identifiers::Amendment.attributes.key?(:year)).to be(false)
      expect(Pubid::Bsi::Identifiers::Amendment.attributes.key?(:date)).to be(true)
      expect(Pubid::Bsi::Identifiers::Amendment.supplement_date_attributes)
        .to eq(%i[date])
    end

    it "holds the corrigendum's own date in the inherited `date`" do
      expect(Pubid::Bsi::Identifiers::Corrigendum.attributes.key?(:year)).to be(false)
      expect(Pubid::Bsi::Identifiers::Corrigendum.attributes.key?(:date)).to be(true)
      expect(Pubid::Bsi::Identifiers::Corrigendum.supplement_date_attributes)
        .to eq(%i[date])
    end

    it "drops only the base standard's date when consolidated" do
      parsed = Pubid::Bsi.parse("BS 7273-4:2015+A1:2021")

      expect(parsed.exclude(:date).to_s).to eq("BS 7273-4+A1:2021")
    end

    it "reads the amendment's own year through the same reader as before" do
      amendment = Pubid::Bsi.parse("BS 4592-0:2006+A1:2012").identifiers[1]

      expect(amendment.year).to eq("2012")
      expect(amendment.to_hash).to include("number" => "1", "year" => "2012")
    end

    it "round-trips an amendment through from_hash unchanged" do
      id = Pubid::Bsi.parse("BS 4592-0:2006+A1:2012")

      expect(Pubid::Bsi::Identifier.from_hash(id.to_hash)).to eq(id)
    end

    # Open question, deliberately not resolved here: `dated_version_of?`/
    # `draft_of?` compare `exclude(:date, :year[, …])` — like every bare
    # :date/:year exclusion, that now protects a supplement's own date unless
    # :supplement_year is also passed. Two
    # standalone BSI amendments differing only in their OWN year are no
    # longer `dated_version_of?` each other (they were before this fix,
    # because BSI's old `year`-attribute dodge only protected against a bare
    # `exclude(:date)`, not `exclude(:year)`). This pins CURRENT behavior,
    # not a verdict that it's correct: CEN/CENELEC already behaved this way
    # before this branch (see lib/pubid/bsi/CLAUDE.md), but whether these two
    # generic predicates should instead be widened to recognize two
    # differently-dated editions of the SAME supplement is left open pending
    # feedback.
    it "makes dated_version_of? consistent with CEN/CENELEC for a supplement's own year" do
      a = Pubid::Bsi.parse("BS 7273-4:2015+A1:2021")
      b = Pubid::Bsi.parse("BS 7273-4:2015+A1:2022")
      cen_a = Pubid::CenCenelec.parse("EN 13250:2000/A1:2005")
      cen_b = Pubid::CenCenelec.parse("EN 13250:2000/A1:2006")

      expect(a.dated_version_of?(b)).to be(false)
      expect(cen_a.dated_version_of?(cen_b)).to be(false)
    end
  end
end
