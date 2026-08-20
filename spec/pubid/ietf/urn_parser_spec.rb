# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/urn_round_trip"

RSpec.describe Pubid::Ietf::UrnParser do
  it_behaves_like "flavor URN round-trip", Pubid::Ietf, [
    "RFC 2119",
    "BCP 3",
    "STD 66",
    "FYI 1",
    "draft-giuliano-treedn-02",
    "draft-giuliano-treedn",
    "draft-adams-cast-256",
    "draft-ietf-pilc-2.5g3g-12",
    "draft-chapin-clnp-ISO8473-00",
  ]

  # Asserts the SPECIFIC class: the raise used to name an unresolvable
  # constant, so it raised NameError — which a bare `StandardError`
  # expectation happily accepted while the intended error never fired.
  it "rejects a URN with an unknown type token" do
    expect { described_class.parse("urn:ietf:bogus:1") }
      .to raise_error(Pubid::UrnParser::Errors::ParseError,
                      /Invalid IETF URN type/)
  end
end
