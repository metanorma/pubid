# frozen_string_literal: true

require "rspec"
require_relative "../../../lib/pubid/itu"
require_relative "../../support/urn_round_trip"

RSpec.describe Pubid::Itu::UrnParser do
  it_behaves_like "flavor URN round-trip", Pubid::Itu, [
    "ITU-T BO.1073-1",
    "ITU-T G.711",
    "Report ITU-R BT.2020-1",
  ]
end
