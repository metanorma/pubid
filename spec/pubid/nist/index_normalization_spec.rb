require "spec_helper"

require "pubid"

RSpec.describe "NIST index suffix normalization (pubid#557)" do
  # The index suffix parses from both spellings; the component's value is
  # the long form either way, so parse(render(x)) == x for the CRPL-F-B
  # corpus rows that print "indx" (relaton-data-nist index-v2).
  { "NBS CRPL-F-B 1960indx" => "index",
    "NBS CRPL-F-B 1962indx" => "index",
    "NBS CRPL-F-B 1963indx" => "index",
    "NBS CRPL-F-B 1964indx" => "index",
    "NBS CIRC 54indx" => "index",
    "NBS NSRDS 63indx" => "index" }.each do |code, expected|
    it "normalizes #{code.inspect}" do
      id = Pubid::Nist.parse(code)
      expect(id.index).to eq(expected)
      expect(id.to_s).to eq(code)
    end
  end

  it "parses the long spelling identically" do
    id = Pubid::Nist.parse("NBS CRPL-F-B 1960index")
    expect(id.index).to eq("index")
    expect(id.to_s).to eq("NBS CRPL-F-B 1960indx")
  end
end
