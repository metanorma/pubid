# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Ieee::Components::Relationship do
  describe "constants" do
    it "defines all relationship types" do
      expect(described_class::REVISION_OF).to eq("revision_of")
      expect(described_class::AMENDMENT_TO).to eq("amendment_to")
      expect(described_class::CORRIGENDUM_TO).to eq("corrigendum_to")
      expect(described_class::INCORPORATES).to eq("incorporates")
      expect(described_class::INCORPORATING).to eq("incorporating")
      expect(described_class::ADOPTION_OF).to eq("adoption_of")
      expect(described_class::SUPPLEMENT_TO).to eq("supplement_to")
      expect(described_class::DRAFT_AMENDMENT_TO).to eq("draft_amendment_to")
      expect(described_class::DRAFT_REVISION_OF).to eq("draft_revision_of")
      expect(described_class::REAFFIRMATION_OF).to eq("reaffirmation_of")
      expect(described_class::REDESIGNATION_OF).to eq("redesignation_of")
    end

    it "includes all types in VALID_TYPES" do
      expect(described_class::VALID_TYPES).to include(
        described_class::REVISION_OF,
        described_class::AMENDMENT_TO,
        described_class::CORRIGENDUM_TO,
        described_class::INCORPORATES,
        described_class::INCORPORATING,
        described_class::ADOPTION_OF,
        described_class::SUPPLEMENT_TO,
        described_class::DRAFT_AMENDMENT_TO,
        described_class::DRAFT_REVISION_OF,
        described_class::REAFFIRMATION_OF,
        described_class::REDESIGNATION_OF,
      )
    end
  end

  describe "#initialize" do
    it "accepts valid relationship type" do
      relationship = described_class.new(
        relationship_type: described_class::REVISION_OF,
      )
      expect(relationship.relationship_type).to eq("revision_of")
    end

    it "raises error for invalid relationship type" do
      expect do
        described_class.new(relationship_type: "invalid_type")
      end.to raise_error(ArgumentError, /Invalid relationship type/)
    end

    it "accepts nil relationship type without validation" do
      relationship = described_class.new
      expect(relationship.relationship_type).to be_nil
    end
  end

  describe "#to_s with single identifier" do
    let(:related_id) do
      Pubid::Ieee::Identifier.new(
        publisher: "IEEE",
        type: "Std",
        code: "802.11",
        year: "2012",
      )
    end

    it "renders revision_of" do
      relationship = described_class.new(
        relationship_type: described_class::REVISION_OF,
        related_identifiers: [related_id],
      )
      expect(relationship.to_s).to eq("Revision of IEEE Std 802.11-2012")
    end

    it "renders amendment_to" do
      relationship = described_class.new(
        relationship_type: described_class::AMENDMENT_TO,
        related_identifiers: [related_id],
      )
      expect(relationship.to_s).to eq("Amendment to IEEE Std 802.11-2012")
    end

    it "renders corrigendum_to" do
      relationship = described_class.new(
        relationship_type: described_class::CORRIGENDUM_TO,
        related_identifiers: [related_id],
      )
      expect(relationship.to_s).to eq("Corrigendum to IEEE Std 802.11-2012")
    end

    it "renders incorporates" do
      relationship = described_class.new(
        relationship_type: described_class::INCORPORATES,
        related_identifiers: [related_id],
      )
      expect(relationship.to_s).to eq("incorporates IEEE Std 802.11-2012")
    end

    it "renders adoption_of" do
      relationship = described_class.new(
        relationship_type: described_class::ADOPTION_OF,
        related_identifiers: [related_id],
      )
      expect(relationship.to_s).to eq("Adoption of IEEE Std 802.11-2012")
    end

    it "renders reaffirmation_of" do
      relationship = described_class.new(
        relationship_type: described_class::REAFFIRMATION_OF,
        related_identifiers: [related_id],
      )
      expect(relationship.to_s).to eq("Reaffirmation of IEEE Std 802.11-2012")
    end

    it "renders redesignation_of" do
      relationship = described_class.new(
        relationship_type: described_class::REDESIGNATION_OF,
        related_identifiers: [related_id],
      )
      expect(relationship.to_s).to eq("Redesignation of IEEE Std 802.11-2012")
    end
  end

  describe "#to_s with two identifiers" do
    let(:id1) do
      Pubid::Ieee::Identifier.new(
        publisher: "IEEE",
        type: "Std",
        code: "1232",
        year: "1995",
      )
    end

    let(:id2) do
      Pubid::Ieee::Identifier.new(
        publisher: "IEEE",
        type: "Std",
        code: "1232.1",
        year: "1997",
      )
    end

    it "uses 'and' for two identifiers" do
      relationship = described_class.new(
        relationship_type: described_class::REVISION_OF,
        related_identifiers: [id1, id2],
      )
      expect(relationship.to_s).to eq("Revision of IEEE Std 1232-1995 and IEEE Std 1232.1-1997")
    end
  end

  describe "#to_s with three or more identifiers" do
    let(:id1) do
      Pubid::Ieee::Identifier.new(
        publisher: "IEEE",
        type: "Std",
        code: "1232",
        year: "1995",
      )
    end

    let(:id2) do
      Pubid::Ieee::Identifier.new(
        publisher: "IEEE",
        type: "Std",
        code: "1232.1",
        year: "1997",
      )
    end

    let(:id3) do
      Pubid::Ieee::Identifier.new(
        publisher: "IEEE",
        type: "Std",
        code: "1232.2",
        year: "1998",
      )
    end

    it "uses Oxford comma for three identifiers" do
      relationship = described_class.new(
        relationship_type: described_class::REVISION_OF,
        related_identifiers: [id1, id2, id3],
      )
      expect(relationship.to_s).to eq("Revision of IEEE Std 1232-1995, IEEE Std 1232.1-1997, and IEEE Std 1232.2-1998")
    end
  end

  describe "#to_s with intermediate amendments" do
    let(:base_id) do
      Pubid::Ieee::Identifier.new(
        publisher: "IEEE",
        type: "Std",
        code: "802.1Q",
        year: "2014",
      )
    end

    let(:amendment1) do
      Pubid::Ieee::Identifier.new(
        publisher: "IEEE",
        type: "Std",
        code: "802.1Qca",
        year: "2015",
      )
    end

    let(:amendment2) do
      Pubid::Ieee::Identifier.new(
        publisher: "IEEE",
        type: "Std",
        code: "802.1Qcd",
        year: "2015",
      )
    end

    it "includes 'as amended by' clause with single amendment" do
      relationship = described_class.new(
        relationship_type: described_class::AMENDMENT_TO,
        related_identifiers: [base_id],
        intermediate_amendments: [amendment1],
      )
      expect(relationship.to_s).to eq("Amendment to IEEE Std 802.1Q-2014 as amended by IEEE Std 802.1Qca-2015")
    end

    it "includes 'as amended by' clause with multiple amendments" do
      relationship = described_class.new(
        relationship_type: described_class::AMENDMENT_TO,
        related_identifiers: [base_id],
        intermediate_amendments: [amendment1, amendment2],
      )
      expect(relationship.to_s).to eq("Amendment to IEEE Std 802.1Q-2014 as amended by IEEE Std 802.1Qca-2015 and IEEE Std 802.1Qcd-2015")
    end
  end

  describe "edge cases" do
    it "returns empty string when no related identifiers" do
      relationship = described_class.new(
        relationship_type: described_class::REVISION_OF,
      )
      expect(relationship.to_s).to eq("")
    end

    it "returns empty string when related_identifiers is empty array" do
      relationship = described_class.new(
        relationship_type: described_class::REVISION_OF,
        related_identifiers: [],
      )
      expect(relationship.to_s).to eq("")
    end
  end

  describe "integration tests with parsing" do
    context "semicolon separator for multiple relationships" do
      it "parses Reaffirmation and Redesignation with semicolon" do
        id = Pubid::Ieee.parse("ANSI N42.18-2004 (Reaffirmation of ANSI N42.18-1980; Redesignation of ANSI N13.10-1974)")
        expect(id.relationships).not_to be_empty
        expect(id.relationships.length).to eq(2)
        expect(id.relationships[0].relationship_type).to eq("reaffirmation_of")
        expect(id.relationships[1].relationship_type).to eq("redesignation_of")
      end

      it "preserves semicolon-separated relationships on the object" do
        id = Pubid::Ieee.parse("IEEE Std 100 (Reaffirmation of ANSI X; Redesignation of ANSI Y)")
        expect(id.relationships.length).to eq(2)
        # The descriptive relationship narrative is deliberately kept out of
        # to_s (bounded identifier string); it stays reachable on the objects.
        expect(id.to_s).to eq("IEEE Std 100")
        expect(id.relationships.map(&:relationship_type))
          .to eq(%w[reaffirmation_of redesignation_of])
      end
    end

    context "reaffirmation relationship parsing" do
      it "parses long form reaffirmation" do
        id = Pubid::Ieee.parse("ANSI N42.18-2004 (Reaffirmation of ANSI N42.18-1980)")
        expect(id.relationships).not_to be_empty
        expect(id.relationships.first.relationship_type).to eq("reaffirmation_of")
        expect(id.relationships.first.related_identifiers.first.to_s).to include("N42.18-1980")
      end

      it "round-trips reaffirmation relationship" do
        original = "ANSI N42.18-2004 (Reaffirmation of ANSI N42.18-1980)"
        parsed = Pubid::Ieee.parse(original)
        expect(parsed.relationships.first.relationship_type).to eq("reaffirmation_of")
      end
    end

    context "redesignation relationship parsing" do
      it "parses redesignation relationship" do
        id = Pubid::Ieee.parse("ANSI N42.18-2004 (Redesignation of ANSI N13.10-1974)")
        expect(id.relationships).not_to be_empty
        expect(id.relationships.first.relationship_type).to eq("redesignation_of")
        expect(id.relationships.first.related_identifiers.first.to_s).to include("N13.10-1974")
      end
    end
  end
end
