require "spec_helper"
require_relative "../../../../lib/pubid"

RSpec.describe Pubid::Ieee::Identifier do
  describe ".parse" do
    context "basic IEEE identifiers" do
      it "parses IEEE Std identifiers" do
        id = Pubid::Ieee.parse("IEEE Std 623-1976")
        expect(id).to be_a(described_class)

        expect(id.code.to_s).to eq("623")
        expect(id.year).to eq("1976")

        expect(id.to_s).to eq("IEEE Std 623-1976")
      end

      it "parses IEEE Std with letter prefix codes" do
        id = Pubid::Ieee.parse("IEEE Std C37.111-2013")

        expect(id).to be_a(described_class)
        expect(id.code.to_s).to eq("C37.111")
        expect(id.year).to eq("2013")

        expect(id.to_s).to eq("IEEE Std C37.111-2013")
      end

      it "parses the historical IEEE/IPCEA S-designation cable standard" do
        id = Pubid::Ieee.parse("IEEE S-135/IPCEA P-46-426-1962")

        expect(id).to be_a(described_class)
        expect(id.code.to_s).to eq("S-135")
        expect(id.root.number).to eq("S-135")

        expect(id.to_s).to eq("IEEE Std S-135/IPCEA P-46-426-1962")
      end

      it "parses IEEE P (project) identifiers" do
        id = Pubid::Ieee.parse("IEEE P11073-10404/D10")

        expect(id).to be_a(described_class)
        expect(id.code.to_s).to eq("11073-10404")
        expect(id.draft_obj.version).to eq("10")

        expect(id.to_s).to eq("IEEE P11073-10404/D10")
      end

      it "parses AIEE identifiers" do
        id = Pubid::Ieee.parse("AIEE No 14-1925")
        expect(id).to be_a(Pubid::Ieee::Aiee::Identifier)
        expect(id.number).to eq("14")
        expect(id.year).to eq("1925") # Year is stored as String for consistency with Base
        expect(id.to_s).to eq("AIEE No 14-1925")
      end
    end

    context "IEC identifiers" do
      it "parses basic IEC identifiers" do
        id = Pubid::Ieee.parse("IEC 61523-4")
        expect(id.to_s).to eq("IEC 61523-4")
      end

      it "parses IEC with edition format" do
        id = Pubid::Ieee.parse("IEC 61671-2 Edition 1.0 2016-04")
        expect(id.to_s).to eq("IEC 61671-2 Edition 1.0 2016-04")
      end
    end

    context "parenthetical content" do
      # NOTE: These tests document where V2 intentionally differs from V1 due to V1 bugs:
      # - V1 incorrectly changes "006-0975" to "006.0975" (dot instead of dash)
      # - V1 incorrectly drops "No" from AIEE rendering
      # - V1 stores parenthetical as string instead of parsing (anti-pattern)
      # V2 correctly uses MODEL-DRIVEN architecture to parse identifiers within parenthetical

      it "parses multi-part adoptions with commas" do
        # Multi-part adoptions (comma-separated) supported in V2
        id = Pubid::Ieee.parse("IEEE Std 623-1976 (ANSI Y32.21-1976, NCTA 006-0975)")

        expect(id).to be_a(Pubid::Ieee::Identifiers::AdoptedStandard)
        expect(id.ieee_identifier.to_s).to eq("IEEE Std 623-1976")

        adopted_identifiers = id.adopted_identifiers
        expect(adopted_identifiers.size).to eq(2)

        ansi_identifier = adopted_identifiers.first
        expect(ansi_identifier).to be_a(Pubid::Ansi::Identifiers::Standard)
        expect(ansi_identifier.to_s).to eq("ANSI Y32.21-1976")
        expect(ansi_identifier.publisher.body).to eq("ANSI")
        expect(ansi_identifier.part).to eq("1976")

        ncta_identifier = adopted_identifiers.last
        expect(ncta_identifier).to be_a(described_class)
        expect(ncta_identifier.to_s).to eq("NCTA 006-0975")

        expect(id.to_s).to match("IEEE Std 623-1976 (ANSI Y32.21-1976 and NCTA 006-0975)")
      end

      it "parses AIEE with Supersedes relationship" do
        id = Pubid::Ieee.parse("AIEE No 19-1943 (Supercedes A. I. E. E. Standard No. 19-1938)")

        expect(id).to be_a(Pubid::Ieee::Aiee::Identifier)
        expect(id.number.to_s).to eq("19")
        expect(id.year).to eq("1943")
        expect(id.relationships.size).to eq(1)

        relationship = id.relationships.first
        expect(relationship.relationship_type).to eq(Pubid::Ieee::Components::Relationship::SUPERSEDES)
        expect(relationship.related_identifiers.size).to eq(1)

        related_id = relationship.related_identifiers.first
        expect(related_id).to be_a(Pubid::Ieee::Aiee::Identifier)
        expect(related_id.number.to_s).to eq("19")
        expect(related_id.year).to eq("1938")

        # The descriptive relationship narrative is deliberately kept out of
        # to_s (bounded identifier string); it stays reachable on `relationships`.
        expect(id.to_s).to eq("AIEE No 19-1943")
      end
    end

    context "relationships" do
      let(:related_id) do
        described_class.new(
          publisher: "IEEE",
          type: "Std",
          code: "802.11",
          year: "2012",
        )
      end

      it "renders the bare identifier, preserving a single relationship on the object" do
        relationship = Pubid::Ieee::Components::Relationship.new(
          relationship_type: Pubid::Ieee::Components::Relationship::REVISION_OF,
          related_identifiers: [related_id],
        )

        id = described_class.new(
          publisher: "IEEE",
          type: "Std",
          code: "802.11",
          year: "2016",
          relationships: [relationship],
        )

        # Descriptive narrative kept out of to_s; still available on relationships.
        expect(id.to_s).to eq("IEEE Std 802.11-2016")
        expect(id.relationships.first.to_s)
          .to eq("Revision of IEEE Std 802.11-2012")
      end

      it "renders the bare identifier, preserving multiple relationships on the object" do
        rev_rel = Pubid::Ieee::Components::Relationship.new(
          relationship_type: Pubid::Ieee::Components::Relationship::REVISION_OF,
          related_identifiers: [related_id],
        )

        inc_rel = Pubid::Ieee::Components::Relationship.new(
          relationship_type: Pubid::Ieee::Components::Relationship::INCORPORATES,
          related_identifiers: [described_class.new(
            publisher: "IEEE",
            type: "Std",
            code: "802.11a",
            year: "1999",
          )],
        )

        id = described_class.new(
          publisher: "IEEE",
          type: "Std",
          code: "802.11",
          year: "2016",
          relationships: [rev_rel, inc_rel],
        )

        expect(id.to_s).to eq("IEEE Std 802.11-2016")
        expect(id.relationships.map(&:relationship_type))
          .to eq(%w[revision_of incorporates])
      end

      it "renders the bare identifier, preserving a relationship with multiple identifiers on the object" do
        id1 = described_class.new(
          publisher: "IEEE",
          type: "Std",
          code: "1232",
          year: "1995",
        )

        id2 = described_class.new(
          publisher: "IEEE",
          type: "Std",
          code: "1232.1",
          year: "1997",
        )

        relationship = Pubid::Ieee::Components::Relationship.new(
          relationship_type: Pubid::Ieee::Components::Relationship::REVISION_OF,
          related_identifiers: [id1, id2],
        )

        id = described_class.new(
          publisher: "IEEE",
          type: "Std",
          code: "1232",
          year: "2002",
          relationships: [relationship],
        )

        expect(id.to_s).to eq("IEEE Std 1232-2002")
        expect(id.relationships.first.to_s)
          .to eq("Revision of IEEE Std 1232-1995 and IEEE Std 1232.1-1997")
      end
    end

    context "round-trip parsing" do
      it "preserves exact rendering" do
        test_cases = [
          "IEEE Std 623-1976",
          "IEEE Std C37.111-2013",
          "IEEE P11073-10404-10419",
          "IEC 61523-4",
          "AIEE No 14-1925",
          # NOTE: Parenthetical content tests above show V2's MODEL-DRIVEN approach
          # differs from V1's buggy string preservation
        ]

        test_cases.each do |test_case|
          expect(Pubid::Ieee.parse(test_case).to_s).to eq(test_case)
        end
      end
    end
  end
end
