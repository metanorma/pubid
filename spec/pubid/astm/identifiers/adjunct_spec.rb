# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Astm::Identifiers::Adjunct do
  # ========================================
  # Adjunct (4 IDs, 1%)
  # ========================================

  describe "parses simple adjunct" do
    subject { "ASTM ADJD2148" }

    let(:parsed) { Pubid::Astm.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("D2148")
      expect(parsed.to_s).to eq("ASTM ADJD2148")
    end
  end

  describe "parses adjunct with EA suffix" do
    subject { "ADJF3504-EA" }

    let(:parsed) { Pubid::Astm.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("F3504")
      expect(parsed.ea_suffix).to be(true)
      expect(parsed.to_s).to eq("ADJF3504-EA")
    end
  end

  describe "parses adjunct with DVD suffix" do
    subject { "ADJG0088DVD" }

    let(:parsed) { Pubid::Astm.parse(subject) }

    it "parses" do
      expect(parsed).to be_a(described_class)
      expect(parsed.number).to eq("G0088")
      expect(parsed.dvd_suffix).to be(true)
      expect(parsed.to_s).to eq("ADJG0088DVD")
    end
  end
end
