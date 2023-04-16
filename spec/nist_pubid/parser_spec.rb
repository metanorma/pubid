require "parslet/rig/rspec"

RSpec.describe Pubid::Nist::Parser do
  describe "find parser for series" do
    it "returns parser for series with separate parser" do
      expect(described_class.new.find_parser("NIST SP")).to eq(Pubid::Nist::Parsers::NistSp)
    end

    it "returns DocumentParser for series without separate parser" do
      expect(described_class.new.find_parser("NOT EXISTING SERIES")).to eq(Pubid::Nist::Parsers::Default)
    end
  end
end
