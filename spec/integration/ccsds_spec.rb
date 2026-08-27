# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/pubid/ccsds"

RSpec.describe "CCSDS Integration" do
  describe "parsing and rendering" do
    shared_examples "parses and renders correctly" do |input, expected_output = nil|
      it "parses and renders #{input}" do
        expected = expected_output || input
        identifier = Pubid::Ccsds.parse(input)
        expect(identifier.to_s).to eq(expected)
      end
    end

    context "basic formats" do
      it_behaves_like "parses and renders correctly", "CCSDS 120.0-G-4"
      it_behaves_like "parses and renders correctly", "CCSDS 121.0-B-3"
      it_behaves_like "parses and renders correctly", "CCSDS 130.0-G-4"
    end

    context "with corrigenda" do
      it_behaves_like "parses and renders correctly", "CCSDS 123.0-B-2 Cor. 1"
      it_behaves_like "parses and renders correctly", "CCSDS 123.0-B-2 Cor. 2"
    end
  end
end
