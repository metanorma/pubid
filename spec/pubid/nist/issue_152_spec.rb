# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/pubid"

# Regression coverage for the identifiers listed in metanorma/pubid#152
# ("Not parsable Identifiers from NIST Tech Pubs"). Most were fixed during the
# v2 rewrite; this spec locks them and covers the two remaining gaps: the
# doubled source prefix and the year-only CIRC series supplement.
RSpec.describe "Pubid::Nist issue #152 identifiers" do
  # Already-parsing forms — guard against regression of their space form.
  {
    "NIST AI 100-1" => "NIST AI 100-1",
    "NIST AI 100-3" => "NIST AI 100-3",
    "NIST VTS 100-1" => "NIST VTS 100-1",
    "NIST VTS 400-5" => "NIST VTS 400-5",
    "NIST AMS 100-48-upd1" => "NIST AMS 100-48/Upd1",
    "NIST FIPS 197-upd1" => "NIST FIPS 197/Upd1",
    "NIST IR 8165-upd1" => "NIST IR 8165/Upd1",
    "NIST IR 8455-upd1" => "NIST IR 8455/Upd1",
    "NIST TN 2221-upd1" => "NIST TN 2221/Upd1",
    "NIST TN 2228-upd1" => "NIST TN 2228/Upd1",
    "NIST TN 2230-upd1" => "NIST TN 2230/Upd1",
  }.each do |input, expected|
    it "parses #{input.inspect} to #{expected.inspect}" do
      expect(Pubid::Nist.parse(input).to_s).to eq(expected)
    end
  end

  context "doubled source prefix (error in source)" do
    it "dedupes 'NIST AI NIST AI ...' and parses" do
      id = Pubid::Nist.parse("NIST AI NIST AI 100-2e2023 ipd")
      expect(id.to_s).to eq("NIST AI 100-2e2023 ipd")
    end
  end

  context "year-only CIRC series supplement" do
    it "models 'NBS CIRC sup1925-1926' as a series-level year range" do
      id = Pubid::Nist.parse("NBS CIRC sup1925-1926")
      expect(id.to_s).to eq("NBS CIRC sup1925-1926")
      supp = id.to_hash["supplement"]
      expect(supp).to include("year" => "1925", "year_end" => "1926")
      expect(supp).not_to include("month")
      expect(id.to_hash).not_to include("edition")
    end

    it "models 'NBS CIRC sup1925-1927' as a series-level year range" do
      id = Pubid::Nist.parse("NBS CIRC sup1925-1927")
      expect(id.to_s).to eq("NBS CIRC sup1925-1927")
      expect(id.to_hash["supplement"]).to include("year" => "1925", "year_end" => "1927")
    end

    it "leaves the month-qualified item-supplement remap unchanged" do
      expect(Pubid::Nist.parse("NBS CIRC supJun1925-Jun1926").to_s)
        .to eq("NBS CIRC 24e7sup2")
    end
  end
end
