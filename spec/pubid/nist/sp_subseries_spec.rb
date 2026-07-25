# frozen_string_literal: true

require "spec_helper"

RSpec.describe "NIST SP subseries — issue #161" do
  # Per Appendix A.2 of the NIST PubID Syntax (April 2022), the SP series is
  # subdivided into named subseries (SP 250, SP 260, ..., SP 800, SP 1190GB,
  # ..., SP 2100). The Builder exposes the subseries code as a queryable
  # attribute so callers can recognize, e.g., every "SP 800-X" document as
  # belonging to the Computer Security subseries.
  describe "#subseries" do
    {
      "NIST SP 800-53" => "800",
      "NIST SP 800-90r1" => "800",
      "NIST SP 800-90B" => "800",
      "NIST SP 250-7" => "250",
      "NIST SP 1190GB-12" => "1190GB",
      "NIST SP 1190GB-4A" => "1190GB",
      "NIST SP 1800-13B" => "1800",
      "NIST SP 1500-7r2" => "1500",
      "NIST SP 2100-5" => "2100",
      "NIST SP 800" => "800",
    }.each do |input, expected|
      it "exposes #{expected.inspect} for #{input.inspect}" do
        parsed = Pubid::Nist.parse(input)
        expect(parsed.subseries&.value).to eq(expected)
      end
    end

    {
      "NIST SP 955" => nil, # 955 is not a known subseries
      "NIST SP 964indx" => nil,
      "NIST TN 2135sup" => nil, # TN series — no subseries concept
      "NIST IR 8183Av1" => nil,
      "NIST FIPS 140-2" => nil,
    }.each do |input, expected|
      it "is #{expected.inspect} for #{input.inspect}" do
        parsed = Pubid::Nist.parse(input)
        expect(parsed.subseries&.value).to eq(expected)
      end
    end
  end

  describe "rendering is unchanged" do
    # The subseries attribute is informational metadata derived from
    # series+number. Existing display and indexing must stay byte-identical.
    [
      "NIST SP 800-53",
      "NIST SP 1190GB-12",
      "NIST SP 1800-13B",
    ].each do |input|
      it "round-trips #{input.inspect}" do
        expect(Pubid::Nist.parse(input).to_s).to eq(input)
      end
    end
  end

  describe "equality" do
    # subseries lives in EQUALITY_IGNORED_ATTRS (it's derived from series+
    # number), so a manually-built id without subseries still equals a parsed
    # one — the canonical no-defaults to_hash invariant.
    it "treats subseries as informational" do
      parsed = Pubid::Nist.parse("NIST SP 800-53")
      expect(parsed.subseries&.value).to eq("800")
      expect(parsed.to_hash).to have_key("subseries")
    end

    it "round-trips through to_hash / from_hash" do
      parsed = Pubid::Nist.parse("NIST SP 800-53")
      round = Pubid::Nist::Identifier.from_hash(parsed.to_hash)
      expect(round.subseries&.value).to eq("800")
      expect(round.to_hash).to eq(parsed.to_hash)
    end
  end
end
