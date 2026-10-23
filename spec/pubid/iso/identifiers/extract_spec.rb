require "spec_helper"

RSpec.describe Pubid::Iso::Identifiers::Extract do
  subject { described_class }

  # Note: No sweep test - fixture file iso/iso-extract.txt does not exist
  # The identifier-specific tests below provide adequate coverage

  # Test basic extract identifiers
  context "basic extract identifiers" do
    # Test normal extract with base identifier
    context "extract with base identifier" do
      describe "ISO 1101:1983/Ext 1:1983" do
        subject { "ISO 1101:1983/Ext 1:1983" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:1101:ext:1:1983:v1" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses base identifier number" do
          expect(parsed.base.number).to eq("1101")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("1983")
        end

        it "parses extract number" do
          expect(parsed.number).to eq("1")
        end

        it "parses extract date" do
          expect(parsed.date.year).to eq("1983")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("ext")
        end

        it "provides stage code" do
          expect(parsed.typed_stage.stage_code).to eq("published")
        end

        it "provides typed_stage with abbreviation" do
          expect(parsed.typed_stage.abbr.first).to eq("Ext")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end
  end
end
