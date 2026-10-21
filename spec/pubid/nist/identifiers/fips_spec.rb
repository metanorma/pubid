require "spec_helper"

RSpec.describe Pubid::Nist::Identifiers::FederalInformationProcessingStandards do
  subject { described_class }

  describe ".parse" do
    context "basic FIPS identifiers" do
      describe "FIPS 1" do
        subject { "FIPS 1" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "parses publisher (FIPS has no publisher prefix by default)" do
          expect(parsed.publisher.to_s).to eq("")
        end

        it "parses series" do
          expect(parsed.series.to_s).to eq("FIPS")
        end

        it "parses number" do
          expect(parsed.number).to eq("1")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "FIPS 140" do
        subject { "FIPS 140" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "parses number" do
          expect(parsed.number).to eq("140")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "FIPS with edition" do
      describe "FIPS 14-1971" do
        subject { "FIPS 14-1971" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "normalizes to e1971 format" do
          expect(parsed.to_s).to eq("FIPS 14e1971")
        end

        it "parses edition year" do
          expect(parsed.edition).to be_a(Pubid::Nist::Components::Edition)
          expect(parsed.edition.type).to eq("e")
          expect(parsed.edition.id).to eq("1971")
        end
      end

      describe "FIPS 107e198503" do
        subject { "FIPS 107e198503" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "parses edition with month+year normalized to number" do
          expect(parsed.edition).to be_a(Pubid::Nist::Components::Edition)
          expect(parsed.edition.type).to eq("e")
          expect(parsed.edition.id).to eq("198503")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "FIPS 107-Mar1985" do
        subject { "FIPS 107-Mar1985" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "normalizes month+year to number format (e198503)" do
          expect(parsed.to_s).to eq("FIPS 107e198503")
        end

        it "parses edition with month+year (converts to number format)" do
          expect(parsed.edition).to be_a(Pubid::Nist::Components::Edition)
          expect(parsed.edition.type).to eq("e")
          expect(parsed.edition.id).to eq("198503")
        end
      end

      describe "FIPS 11-1-Sep30/1977" do
        subject { "FIPS 11-1-Sep30/1977" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "normalizes month+day+year to number format (e19770930)" do
          expect(parsed.to_s).to eq("FIPS 11-1e19770930")
        end

        it "parses edition with month+day+year (converts to number format)" do
          expect(parsed.edition).to be_a(Pubid::Nist::Components::Edition)
          expect(parsed.edition.type).to eq("e")
          expect(parsed.edition.id).to eq("19770930")
        end
      end

      describe "FIPS 46e1993" do
        subject { "FIPS 46e1993" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "parses edition year" do
          expect(parsed.edition).to be_a(Pubid::Nist::Components::Edition)
          expect(parsed.edition.type).to eq("e")
          expect(parsed.edition.id).to eq("1993")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "FIPS 46-1977" do
        subject { "FIPS 46-1977" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "normalizes to e1977 format" do
          expect(parsed.to_s).to eq("FIPS 46e1977")
        end

        it "parses edition year" do
          expect(parsed.edition).to be_a(Pubid::Nist::Components::Edition)
          expect(parsed.edition.type).to eq("e")
          expect(parsed.edition.id).to eq("1977")
        end
      end
    end

    context "FIPS with parts" do
      describe "FIPS 140-1" do
        subject { "FIPS 140-1" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "parses part" do
          expect(parsed.number.split("-").last).to eq("1")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "FIPS 140-2" do
        subject { "FIPS 140-2" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "parses part" do
          expect(parsed.number.split("-").last).to eq("2")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end

      describe "FIPS 140-3" do
        subject { "FIPS 140-3" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "parses part" do
          expect(parsed.number.split("-").last).to eq("3")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "FIPS with letter suffix" do
      describe "FIPS 46a" do
        subject { "FIPS 46a" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "normalizes letter to uppercase" do
          expect(parsed.to_s).to eq("FIPS 46A")
        end

        it "parses letter suffix" do
          expect(parsed.number).to eq("46A")
        end
      end

      describe "FIPS 81A" do
        subject { "FIPS 81A" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "parses letter suffix" do
          expect(parsed.number).to eq("81A")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "FIPS with revision" do
      describe "FIPS 197r2001" do
        subject { "FIPS 197r2001" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "parses revision as edition" do
          expect(parsed.edition).to be_a(Pubid::Nist::Components::Edition)
          expect(parsed.edition.type).to eq("r")
          expect(parsed.edition.id).to eq("2001")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end
      end
    end

    context "FIPS dotted format" do
      describe "FIPS.140-2" do
        subject { "FIPS.140-2" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "round-trips in MR format (format preservation)" do
          expect(parsed.to_s).to eq("FIPS.140-2")
        end

        it "parses part" do
          expect(parsed.number.split("-").last).to eq("2")
        end
      end

      describe "FIPS.46e1993" do
        subject { "FIPS.46e1993" }

        let(:parsed) { Pubid::Nist.parse(subject) }

        it "parses as FederalInformationProcessingStandards" do
          expect(parsed).to be_a(described_class)
        end

        it "round-trips in MR format (format preservation)" do
          expect(parsed.to_s).to eq("FIPS.46e1993")
        end

        it "parses edition" do
          expect(parsed.edition).to be_a(Pubid::Nist::Components::Edition)
          expect(parsed.edition.type).to eq("e")
          expect(parsed.edition.id).to eq("1993")
        end
      end
    end

    # The MR form keeps the parsed publisher, as SP/IR/CSWP do: it is the
    # DOI suffix NIST publishes (10.6028/NIST.FIPS.197-upd1.ipd).
    context "MR render keeps the publisher" do
      %w[
        NIST.FIPS.197 NIST.FIPS.197-upd1 NIST.FIPS.197-upd1.ipd
      ].each do |input|
        it "round-trips #{input} in MR format" do
          expect(Pubid::Nist.parse(input).to_s(:mr)).to eq(input)
        end
      end

      {
        "NIST FIPS 197" => "NIST.FIPS.197",
        "NBS FIPS 63-1sup" => "NBS.FIPS.63-1sup",
        "FIPS 140-3" => "FIPS.140-3",
      }.each do |input, expected|
        it "renders #{input} as #{expected} in MR format" do
          expect(Pubid::Nist.parse(input).to_s(:mr)).to eq(expected)
        end
      end
    end
  end
end
