# frozen_string_literal: true

require "rspec"
require_relative "../../../lib/pubid/w3c"

RSpec.describe "W3C URN Generation" do
  describe "#to_urn" do
    it "generates a namespaced URN for a typed identifier" do
      urn = Pubid::W3c.parse("W3C WD-charmod-19991129").to_urn
      expect(urn).to eq("urn:w3c:wd:charmod:19991129")
    end

    it "generates a URN for a bare slug" do
      urn = Pubid::W3c.parse("W3C 2dcontext").to_urn
      expect(urn).to eq("urn:w3c:2dcontext")
    end

    it "follows the urn: scheme" do
      expect(Pubid::W3c.parse("W3C NOTE-xml-names").to_urn)
        .to start_with("urn:w3c:")
    end
  end
end
