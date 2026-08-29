# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/urn_round_trip"

RSpec.describe Pubid::Tgpp::UrnParser do
  it_behaves_like "flavor URN round-trip", Pubid::Tgpp, [
    "TS 23.207:REL-4/2.0.0",
    "TR 00.01U:UMTS/3.0.0",
    "TS 29.198-04-1:REL-5/5.0.0",
    "TS 02.68:Release 2000/9.0.0",
    "TS 29.215/2.0.0",
    "TS 23.207",
    "TR 00.01U",
    "TS 23.207:REL-4",
  ]
end
