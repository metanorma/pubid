require "spec_helper"

require "pubid"

RSpec.describe "NIST annex suffix (pubid#555)" do
  # The n+UPPER annex designations of the BH/HR/NCSTAR/SP series parse and
  # round-trip their printed form verbatim.
  ["NBS BH 3nA", "NBS BH 5nA", "NIST NCSTAR 1nA", "NBS HR 10nA",
   "NIST SP 800-85nB ipd", "NIST SP 800-85nB-1"].each do |code|
    it "parses and round-trips #{code.inspect}" do
      id = Pubid::Nist.parse(code)
      expect(id.to_s).to eq(code)
    end
  end

  it "parses and round-trips the dashed annex form" do
    expect(Pubid::Nist.parse("NBS HR 1-1nA").to_s).to eq("NBS HR 1-1nA")
  end

  it "casts the dashed annex form to the n-notation part" do
    id = Pubid::Nist.parse("NIST SP 800-85nB-1")
    expect(id.part.value).to eq("B")
  end

  it "still parses the plain letter suffix" do
    expect(Pubid::Nist.parse("NBS BH 3A").to_s).to eq("NBS BH 3A")
    expect(Pubid::Nist.parse("NIST SP 800-85").to_s).to eq("NIST SP 800-85")
  end
end
