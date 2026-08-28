# frozen_string_literal: true

require "spec_helper"

# "EN 196-3:2005+A1:2008" (a consolidated EN with a part) and
# "EN 14988:2017+A1:2020" (part-less) serialize through
# ConsolidatedIdentifier, whose #parts delegation assumed every member
# carries the attribute. SingleIdentifier-chain members (EuropeanNorm)
# do not, so to_hash raised NoMethodError for the whole id - which
# surfaced as a GOST debt row ("ГОСТ 35292-2025 (EN 14988:2017+A1:2020)")
# because gost wraps the parsed EN as a foreign adoption.
RSpec.describe Pubid::CenCenelec::Identifiers::ConsolidatedIdentifier do
  it "serializes a consolidated id with a part-less base document" do
    id = Pubid::CenCenelec.parse("EN 14988:2017+A1:2020")
    expect(id.to_s).to eq("EN 14988:2017+A1:2020")
    type = id.to_hash["_type"]
    expect(type).to eq("pubid:cencenelec:consolidated-identifier")
  end

  it "serializes a consolidated id with a part-bearing base document" do
    id = Pubid::CenCenelec.parse("EN 196-3:2005+A1:2008")
    expect(id.to_s).to eq("EN 196-3:2005+A1:2008")
    type = id.to_hash["_type"]
    expect(type).to eq("pubid:cencenelec:consolidated-identifier")
  end

  it "round-trips both through from_hash" do
    ["EN 14988:2017+A1:2020", "EN 196-3:2005+A1:2008"].each do |ref|
      hash = Pubid::CenCenelec.parse(ref).to_hash
      expect(Pubid::CenCenelec::Identifier.from_hash(hash).to_hash).to eq(hash)
    end
  end

  it "parses and serializes inside a GOST foreign adoption" do
    id = Pubid::Gost.parse("ГОСТ 35292-2025 (EN 14988:2017+A1:2020)")
    expect(id.adopted_identifiers.first)
      .to be_a(Pubid::CenCenelec::Identifiers::ConsolidatedIdentifier)
    expect(id.to_s).to eq("GOST 35292-2025 (EN 14988:2017+A1:2020)")
    expect(id.to_hash.dig("adopted_identifiers", 0, "_type"))
      .to eq("pubid:cencenelec:consolidated-identifier")
  end
end
