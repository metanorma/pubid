# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Pubid::Ecma URN handling" do
  describe "UrnGenerator#generate" do
    {
      "ECMA-411" => "urn:ecma:411",
      "ECMA-418-1" => "urn:ecma:418:part-1",
      "ECMA-418-2" => "urn:ecma:418:part-2",
      "ECMA TR/101" => "urn:ecma:tr:101",
      "ECMA MEM/1970" => "urn:ecma:mem:1970",
      # Edition and volume are identity-bearing, so they must reach the URN as
      # well as `to_s` — otherwise two distinct documents share one URN.
      "ECMA-269 ed3" => "urn:ecma:269:ed-3",
      "ECMA-269 ed3 vol2" => "urn:ecma:269:ed-3:vol-2",
      # The dot survives: `.` is `unreserved` in RFC 8141, and the URN has an
      # inverse, so it must be lossless. (The MR string, which has no inverse,
      # collapses it to "ed5-1" instead.)
      "ECMA-402 ed5.1" => "urn:ecma:402:ed-5.1",
      "ECMA TR/18 ed2" => "urn:ecma:tr:18:ed-2",
      "ECMA MEM/1970 ed1" => "urn:ecma:mem:1970:ed-1",
      "ECMA-418-1 ed2" => "urn:ecma:418:part-1:ed-2",
    }.each do |input, urn|
      it "renders #{input.inspect} as #{urn.inspect}" do
        expect(Pubid::Ecma.parse(input).to_urn).to eq(urn)
      end
    end
  end

  describe "UrnParser#parse_urn (round-trips the generator)" do
    [
      "ECMA-411",
      "ECMA-418-1",
      "ECMA-418-2",
      "ECMA TR/101",
      "ECMA MEM/1970",
      "ECMA-269 ed3",
      "ECMA-269 ed3 vol2",
      "ECMA-402 ed5.1",
      "ECMA TR/18 ed2",
      "ECMA MEM/1970 ed1",
      "ECMA-418-1 ed2",
    ].each do |input|
      it "round-trips #{input.inspect} via URN" do
        urn = Pubid::Ecma.parse(input).to_urn
        expect(Pubid::Ecma::UrnParser.parse(urn).to_s).to eq(input)
      end
    end

    # The `ed-`/`vol-` segments are purely additive: the parser probes for a
    # labelled prefix, so a URN minted before they existed still reads back.
    describe "backward compatibility with suffix-less URNs" do
      {
        "urn:ecma:411" => "ECMA-411",
        "urn:ecma:418:part-1" => "ECMA-418-1",
        "urn:ecma:tr:101" => "ECMA TR/101",
        "urn:ecma:mem:1970" => "ECMA MEM/1970",
      }.each do |urn, expected|
        it "reads #{urn.inspect} back as #{expected.inspect}" do
          expect(Pubid::Ecma::UrnParser.parse(urn).to_s).to eq(expected)
        end
      end
    end

    it "is reachable through global URN dispatch" do
      urn = Pubid::Ecma.parse("ECMA TR/101").to_urn
      expect(Pubid.parse(urn).to_urn).to eq(urn)
    end
  end
end
