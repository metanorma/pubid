# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/pubid/iso"

RSpec.describe "ISO Integration" do
  describe "basic parsing" do
    shared_examples "parses correctly" do |input, expected = nil|
      it "parses #{input}" do
        expect { Pubid::Iso.parse(input) }.not_to raise_error
        id = Pubid::Iso.parse(input)
        expect(id.to_s).to eq(expected || input) if expected
      end
    end

    include_examples "parses correctly", "ISO 123"
    include_examples "parses correctly", "ISO 123:2020"
    include_examples "parses correctly", "ISO 123-1:2020"
    include_examples "parses correctly", "ISO/IEC 13818-1:2015"
    include_examples "parses correctly", "ISO Guide 71:2014"
    include_examples "parses correctly", "ISO GUIDE 1:1972"
    include_examples "parses correctly", "ISO/TR 1234:2020"
    include_examples "parses correctly", "ISO/TS 1234:2020"
  end
end
