# frozen_string_literal: true

require "spec_helper"

RSpec.describe "IETF URN generation" do
  {
    "RFC 2119" => "urn:ietf:rfc:2119",
    "BCP 3" => "urn:ietf:bcp:3",
    "STD 66" => "urn:ietf:std:66",
    "FYI 1" => "urn:ietf:fyi:1",
    "draft-giuliano-treedn-02" => "urn:ietf:id:draft-giuliano-treedn:02",
    "draft-giuliano-treedn" => "urn:ietf:id:draft-giuliano-treedn",
    "draft-ietf-pilc-2.5g3g-12" => "urn:ietf:id:draft-ietf-pilc-2.5g3g:12",
    "draft-chapin-clnp-ISO8473-00" =>
      "urn:ietf:id:draft-chapin-clnp-ISO8473:00",
    # The zero-padded rfc-index.xml spelling normalizes onto the canonical URN.
    "STD0066" => "urn:ietf:std:66",
    "RFC0001" => "urn:ietf:rfc:1",
  }.each do |ref, urn|
    it "renders #{ref.inspect} as #{urn}" do
      expect(Pubid::Ietf.parse(ref).to_urn).to eq(urn)
    end
  end

  it "starts every URN with urn:ietf:" do
    expect(Pubid::Ietf.parse("RFC 1").to_urn).to start_with("urn:ietf:")
  end
end
