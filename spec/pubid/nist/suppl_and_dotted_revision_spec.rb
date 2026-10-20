# frozen_string_literal: true

require "spec_helper"

# The 2026-10-20 residual round: the capitalized catalogue supplement
# spelling ("NIST.SP.955.Suppl") used to be rewritten by a legacy
# update_codes row into the corrupted "NIST.SP.955-S.uppl" face ("S"
# gluing onto the number, "uppl" becoming a translation code). The
# dotted revision spelling ("8278.r1") used to stringify the raw parser
# hash into the number. Both now fold to their canonical faces.
RSpec.describe "NIST Suppl and dotted-revision spellings" do
  describe "the capitalized Suppl spelling" do
    it "renders the clean mr face" do
      expect(Pubid::Nist.parse("NIST.SP.955.Suppl").to_s).to eq("NIST.SP.955")
    end

    it "is idempotent" do
      rendered = Pubid::Nist.parse("NIST.SP.955.Suppl").to_s
      expect(Pubid::Nist.parse(rendered).to_s).to eq(rendered)
    end

    it "keeps the lowercase supplement faces" do
      expect(Pubid::Nist.parse("NIST SP 955sup").to_s).to eq("NIST SP 955sup")
      expect(Pubid::Nist.parse("NIST SP 955 Suppl").to_s).to eq("NIST SP 955sup")
    end

    it "keeps the plain mr face parseable" do
      expect(Pubid::Nist.parse("NIST.SP.955").to_s).to eq("NIST.SP.955")
    end
  end

  describe "the dotted revision spelling" do
    it "folds to the glued edition face" do
      expect(Pubid::Nist.parse("NIST SP 8278.r1").to_s).to eq("NIST SP 8278r1")
    end

    it "keeps the glued spelling and the lettered second numbers" do
      expect(Pubid::Nist.parse("NIST SP 8278r1").to_s).to eq("NIST SP 8278r1")
      expect(Pubid::Nist.parse("NIST SP 800-53r4").to_s).to eq("NIST SP 800-53r4")
      expect(Pubid::Nist.parse("NIST SP 955-SC").to_s).to eq("NIST SP 955-SC")
    end
  end
end
