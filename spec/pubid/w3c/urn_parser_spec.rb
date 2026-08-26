# frozen_string_literal: true

require "rspec"
require_relative "../../../lib/pubid/w3c"
require_relative "../../support/urn_round_trip"

RSpec.describe Pubid::W3c::UrnParser do
  it_behaves_like "flavor URN round-trip", Pubid::W3c, [
    "W3C WD-charmod-19991129",   # type + slug + date
    "W3C NOTE-xml-names",        # type + slug, no date
    "W3C 2dcontext",             # bare slug
    "W3C REC-ATAG10-20000203",   # slug ending in digits
    "W3C NOTE-TPRC-970930",      # legacy 6-digit date
  ]
end
