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

  describe "#related_to?" do
    it "returns true for supplement relationship" do
      expect(amd).to be_related_to(base_iso)
    end

    it "returns true for dated-version relationship" do
      dated = Pubid::Iso.parse("ISO 9001:2015")
      undated = Pubid::Iso.parse("ISO 9001")
      expect(dated).to be_related_to(undated)
    end

    it "returns false for unrelated identifiers" do
      other = Pubid::Iso.parse("ISO 14001:2015")
      expect(base_iso).not_to be_related_to(other)
    end
  end
end
