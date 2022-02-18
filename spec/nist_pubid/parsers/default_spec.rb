require "parslet/rig/rspec"

RSpec.describe NistPubid::Parsers::Default do
  describe "parses series" do
    it "parses revision" do
      expect(described_class.new.revision).to parse("r5")
    end

    it "parses volume" do
      expect(described_class.new).to parse(" 1-1Cv1")
    end

    it "parses part end revision" do
      expect(described_class.new).to parse(" 800-57pt1r4")
    end

    it "parses update" do
      expect(described_class.new.update).to parse("/Upd1-2012")
    end

    it "parses translation" do
      expect(described_class.new.translation.parse("(esp)")).to eq(translation: "esp")
    end

    it "parses edition" do
      expect(described_class.new.edition.parse("e5")).to eq(edition: "5")
    end

    it " 800-53e5" do
      expect(described_class.new).to parse(" 800-53e5")
    end
  end
end
