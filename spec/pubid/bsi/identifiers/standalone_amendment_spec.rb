# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Bsi::Identifiers::StandaloneAmendment do
  describe "parsing" do
    it "parses AMD with number" do
      id = Pubid::Bsi.parse("AMD 11015")
      expect(id.class).to eq(described_class)
      expect(id.number.value).to eq("11015")
    end

    it "parses parenthesized AMD" do
      id = Pubid::Bsi.parse("(AMD 10971)")
      expect(id.class).to eq(described_class)
      expect(id.number.value).to eq("10971")
    end

    it "parses AMD with corrigendum" do
      id = Pubid::Bsi.parse("AMD Corrigendum 14716")
      expect(id.class).to eq(described_class)
      expect(id.number.value).to eq("14716")
      expect(id.corrigendum).to be true
    end
  end

  describe "rendering" do
    it "renders AMD format" do
      id = Pubid::Bsi.parse("AMD 11015")
      expect(id.to_s).to eq("AMD 11015")
    end

    it "renders parenthesized AMD" do
      id = Pubid::Bsi.parse("(AMD 10971)")
      expect(id.to_s).to eq("(AMD 10971)")
    end

    it "renders AMD with corrigendum" do
      id = Pubid::Bsi.parse("AMD Corrigendum 14716")
      expect(id.to_s).to eq("AMD Corrigendum 14716")
    end

    it "maintains round-trip fidelity" do
      original = "AMD 11015"
      id = Pubid::Bsi.parse(original)
      expect(id.to_s).to eq(original)
    end
  end
end
