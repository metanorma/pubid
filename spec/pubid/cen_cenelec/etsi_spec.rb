# frozen_string_literal: true

require "spec_helper"

# The ETSI-collaboration and version forms (pubid ruling 2026-10-13):
# "CEN/CLC/ETSI/TR" carries ETSI as a second copublisher, the ETSI-style
# numbers carry space-separated groups and a "V"-version, and "TR" never
# combines with the EN publisher (a technical report is CEN/TR or CLC/TR).
RSpec.describe "CEN/CENELEC ETSI and version forms" do
  it "parses the CEN/CLC/ETSI/TR triple-copublisher form" do
    expect(Pubid::CenCenelec::Identifier.parse("CEN/CLC/ETSI/TR 101551:2026").to_s)
      .to eq("CEN/CLC/ETSI/TR 101551:2026")
  end

  it "round-trips the ETSI-style version row" do
    expect(Pubid::CenCenelec::Identifier.parse("EN 302 326-2 V2.2.1:2026").to_s)
      .to eq("EN 302 326-2 V2.2.1:2026")
  end

  it "rejects EN TR" do
    expect { Pubid::CenCenelec::Identifier.parse("EN TR 16798:2021") }
      .to raise_error(Pubid::Errors::ParseError)
  end

  it "keeps CEN/TR and CLC/TR" do
    expect(Pubid::CenCenelec::Identifier.parse("CEN/TR 17638:2021").to_s)
      .to eq("CEN/TR 17638:2021")
    expect(Pubid::CenCenelec::Identifier.parse("CLC/TR 60000:2014").to_s)
      .to eq("CLC/TR 60000:2014")
  end
end
