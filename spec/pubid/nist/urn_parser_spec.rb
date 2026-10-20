# frozen_string_literal: true

require "rspec"
require_relative "../../../lib/pubid/nist"
require_relative "../../support/urn_round_trip"

RSpec.describe Pubid::Nist::UrnParser do
  it_behaves_like "flavor URN round-trip", Pubid::Nist, [
    "NIST SP 800-53",
    "NIST SP 800-53r5",
    "NIST FIPS 199",
    "NIST IR 8202",
  ]

  # The Commercial Standards Monthly carries the NBS imprint — the URN
  # rebuild must name the publisher the document carries.
  it "rebuilds the NBS-published CSM series under its own imprint" do
    id = described_class.parse("urn:nist:csm:1.supp")
    expect(id.to_s).to eq("NBS CSM 1")
  end

  it "keeps the NIST prefix for every other series" do
    id = described_class.parse("urn:nist:sp:800-53.r5.supp")
    expect(id.to_s).to eq("NIST SP 800-53r5")
  end

  it "rebuilds the dot-joined edition, volume and revision fields" do
    expect(described_class.parse("urn:nist:circ:13.e2.June1908.supp").to_s)
      .to eq("NIST CIRC 13e2.June1908")
    expect(described_class.parse("urn:nist:circ:539.v10.supp").to_s)
      .to eq("NIST CIRC 539v10")
    expect(described_class.parse("urn:nist:lcirc:256.r1930.supp").to_s)
      .to eq("NIST LCIRC 256r1930")
  end

  it "glues a part letter onto the number" do
    expect(described_class.parse("urn:nist:sp:304.e2017.A.supp").to_s)
      .to eq("NIST SP 304Ae2017")
  end

  it "keeps markers and drops the bare supplementability suffix" do
    expect(described_class.parse("urn:nist:circ:24.supp-1").to_s)
      .to eq("NIST CIRC 24sup1")
    expect(described_class.parse("urn:nist:sp:800-38.A.supp.add.").to_s)
      .to eq("NIST SP 800-38A Add.")
  end
end
