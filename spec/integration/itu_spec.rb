# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/pubid/itu"

RSpec.describe "ITU Integration" do
  describe "parsing and rendering" do
    shared_examples "parses and renders correctly" do |input, expected_output = nil|
      it "parses and renders #{input}" do
        expected = expected_output || input
        identifier = Pubid::Itu.parse(input)
        expect(identifier.to_s).to eq(expected)
      end
    end

    context "ITU-R recommendations" do
      it_behaves_like "parses and renders correctly", "ITU-R BO.600-1"
      it_behaves_like "parses and renders correctly", "ITU-R BO.791-0"
      it_behaves_like "parses and renders correctly", "ITU-R V.1234-1"
    end

    context "with subseries" do
      it_behaves_like "parses and renders correctly", "ITU-R BO.1234.5-2"
    end

    context "ITU-R Handbooks" do
      it_behaves_like "parses and renders correctly", "ITU-R 23.HDB"
      it_behaves_like "parses and renders correctly", "ITU-R 42.HDB"
    end

    context "ITU-R Questions" do
      it_behaves_like "parses and renders correctly", "ITU-R 234-1/7:"
      it_behaves_like "parses and renders correctly", "ITU-R 237/3:"
      it_behaves_like "parses and renders correctly", "ITU-R P.3/BL/7"
      it_behaves_like "parses and renders correctly", "ITU-R SM.1/30"
      it_behaves_like "parses and renders correctly", "ITU-R S.[4/BL/2]:"
    end
  end
end
