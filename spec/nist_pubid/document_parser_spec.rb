require "parslet/rig/rspec"

RSpec.describe NistPubid::DocumentParser do
  describe "find parser for series" do
    it "returns parser for series with separate parser" do
      expect(described_class.new.find_parser("NIST SP")).to eq(NistPubid::Parsers::NistSp)
    end

    it "returns DocumentParser for series without separate parser" do
      expect(described_class.new.find_parser("NIST NCSTAR")).to eq(NistPubid::Parsers::Default)
    end
  end
end
