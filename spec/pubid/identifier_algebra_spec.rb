# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Pubid::Identifier algebra (pubid/pubid#247)" do
  let(:base_iso) { Pubid::Iso.parse("ISO 9001:2015") }
  let(:amd) { Pubid::Iso.parse("ISO 9001:2015/Amd 1:2020") }

  describe "#supplement_of?" do
    it "returns true when self is a supplement of other" do
      expect(amd).to be_supplement_of(base_iso)
    end

    it "returns false for a non-supplement" do
      expect(base_iso).not_to be_supplement_of(amd)
    end

    it "returns false for unrelated identifiers" do
      other = Pubid::Iso.parse("ISO 14001:2015")
      expect(amd).not_to be_supplement_of(other)
    end
  end

  describe "#has_supplement?" do
    it "returns true when other is a supplement of self" do
      expect(base_iso).to have_supplement(amd)
    end

    it "returns false when other is not a supplement" do
      other = Pubid::Iso.parse("ISO 14001:2015")
      expect(base_iso).not_to have_supplement(other)
    end
  end

  describe "#dated_version_of?" do
    let(:dated) { Pubid::Iso.parse("ISO 9001:2015") }
    let(:undated) { Pubid::Iso.parse("ISO 9001") }

    it "returns true when self differs only in date" do
      expect(dated).to be_dated_version_of(undated)
    end

    it "returns false for identical identifiers" do
      expect(dated).not_to be_dated_version_of(dated)
    end
  end

  describe "#sibling_of?" do
    let(:part1) { Pubid::Iso.parse("ISO 9001-1:2015") }
    let(:part2) { Pubid::Iso.parse("ISO 9001-2:2015") }

    it "returns true when same publisher+number, different part" do
      expect(part1).to be_sibling_of(part2)
    end

    it "returns false for different numbers" do
      other = Pubid::Iso.parse("ISO 14001:2015")
      expect(part1).not_to be_sibling_of(other)
    end
  end

  describe "#edition_of?" do
    let(:ed2008) { Pubid::Iso.parse("ISO 9001:2008") }
    let(:ed2015) { Pubid::Iso.parse("ISO 9001:2015") }

    it "returns true when same publisher+number+part, different edition" do
      expect(ed2015).to be_edition_of(ed2008)
    end

    it "returns false for different numbers" do
      other = Pubid::Iso.parse("ISO 14001:2015")
      expect(ed2015).not_to be_edition_of(other)
    end
  end

  describe "consolidated composites (pubid/pubid#449)" do
    let(:a1) { Pubid::Bsi.parse("BS 7273-4:2015+A1:2021") }
    let(:a2) { Pubid::Bsi.parse("BS 7273-4:2015+A2:2023") }
    let(:bare) { Pubid::Bsi.parse("BS 7273-4:2015") }
    let(:other_doc_a1) { Pubid::Bsi.parse("BS 9999-1:2010+A1:2012") }

    it "returns edition_of? between successive consolidated states" do
      expect(a1).to be_edition_of(a2)
      expect(a2).to be_edition_of(a1)
    end

    it "returns false for edition_of? between a composite and its bare base" do
      expect(a1).not_to be_edition_of(bare)
      expect(bare).not_to be_edition_of(a1)
    end

    it "returns false for edition_of? between composites of different documents" do
      expect(a1).not_to be_edition_of(other_doc_a1)
    end

    it "returns sibling_of? between composites of the same document" do
      expect(a1).to be_sibling_of(a2)
    end

    it "returns false for sibling_of? between composites of different documents" do
      expect(a1).not_to be_sibling_of(other_doc_a1)
    end

    it "returns false for dated_version_of? across consolidated states" do
      expect(a1).not_to be_dated_version_of(a2)
    end

    it "keeps the amendment a supplement of the base, not an edition of it" do
      amd = a1.identifiers.last
      expect(amd).to be_supplement_of(bare)
      expect(bare).to have_supplement(amd)
      expect(amd).not_to be_edition_of(bare)
    end

    it "relates the consolidated states to each other" do
      expect(a1).to be_related_to(a2)
    end
  end

  describe "#revision_of?" do
    let(:ogc) { Pubid::Ogc.parse("OGC 06-121") }
    let(:ogc_r9) { Pubid::Ogc.parse("OGC 06-121r9") }

    it "returns true when self carries a revision marker" do
      expect(ogc_r9).to be_revision_of(ogc)
    end

    it "returns false when self carries no revision" do
      expect(ogc).not_to be_revision_of(ogc_r9)
    end

    it "returns false for an unrelated document" do
      other = Pubid::Ogc.parse("OGC 06-152r9")
      expect(ogc_r9).not_to be_revision_of(other)
    end

    it "relates two different revisions of one document" do
      r10 = Pubid::Ogc.parse("OGC 06-121r10")
      expect(ogc_r9).to be_revision_of(r10)
    end

    it "reads the NIST update component as a revision marker" do
      base = Pubid::Nist.parse("NBS LC 800")
      revised = Pubid::Nist.parse("NBS LC 800 rJun1992")
      expect(revised).to be_revision_of(base)
      expect(base).not_to be_revision_of(revised)
    end
  end

  describe "#related_to?" do
    it "returns true for supplement relationship" do
      expect(amd).to be_related_to(base_iso)
    end

    it "returns true for dated-version relationship" do
      dated = Pubid::Iso.parse("ISO 9001:2015")
      undated = Pubid::Iso.parse("ISO 9001")
      expect(dated).to be_related_to(undated)
    end

    it "returns true for a revision relationship" do
      expect(Pubid::Ogc.parse("OGC 06-121r9"))
        .to be_related_to(Pubid::Ogc.parse("OGC 06-121"))
    end

    it "returns false for unrelated identifiers" do
      other = Pubid::Iso.parse("ISO 14001:2015")
      expect(base_iso).not_to be_related_to(other)
    end
  end
end
