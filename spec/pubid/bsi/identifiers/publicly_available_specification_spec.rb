# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Bsi::Identifiers::PubliclyAvailableSpecification do
  subject { described_class }

  context "basic PAS identifiers" do
    describe "PAS 1234:2020" do
      subject { "PAS 1234:2020" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as PubliclyAvailableSpecification" do
        expect(parsed).to be_a(described_class)
      end

      it "has type PAS" do
        expect(parsed.type.abbr).to eq("PAS")
      end

      it "parses number" do
        expect(parsed.number).to eq("1234")
      end

      it "parses year" do
        expect(parsed.date.year).to eq("2020")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    describe "PAS 5678" do
      subject { "PAS 5678" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as PubliclyAvailableSpecification" do
        expect(parsed).to be_a(described_class)
      end

      it "parses number" do
        expect(parsed.number).to eq("5678")
      end

      it "has no date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  context "PAS with parts" do
    describe "PAS 7654-3:2019" do
      subject { "PAS 7654-3:2019" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as PubliclyAvailableSpecification" do
        expect(parsed).to be_a(described_class)
      end

      it "parses number" do
        expect(parsed.number).to eq("7654")
      end

      it "parses part" do
        expect(parsed.part).to eq("3")
      end

      it "parses year" do
        expect(parsed.date.year).to eq("2019")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    describe "PAS 8888-2-1:2020" do
      subject { "PAS 8888-2-1:2020" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as PubliclyAvailableSpecification" do
        expect(parsed).to be_a(described_class)
      end

      it "parses number" do
        expect(parsed.number).to eq("8888")
      end

      it "parses first part level" do
        expect(parsed.part).to eq("2")
      end

      # Multi-level parts are now properly separated by part_with_subpart rule
      it "has subpart from parser" do
        expect(parsed.subpart).to eq("1")
      end

      # Multi-level parts round-trip properly now
      it "round-trips when subpart is supported" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  context "PAS with month" do
    describe "PAS 1234:2020-03" do
      subject { "PAS 1234:2020-03" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as PubliclyAvailableSpecification" do
        expect(parsed).to be_a(described_class)
      end

      it "parses year" do
        expect(parsed.date.year).to eq("2020")
      end

      it "parses month" do
        expect(parsed.month).to eq(3)
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  context "PAS with edition" do
    describe "PAS 5432:2018 v2.0" do
      subject { "PAS 5432:2018 v2.0" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as PubliclyAvailableSpecification" do
        expect(parsed).to be_a(described_class)
      end

      it "parses edition" do
        expect(parsed.edition).to eq("2.0")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end

  context "multi-digit numbers" do
    describe "PAS 10000:2022" do
      subject { "PAS 10000:2022" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as PubliclyAvailableSpecification" do
        expect(parsed).to be_a(described_class)
      end

      it "parses number" do
        expect(parsed.number).to eq("10000")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end
  end
end
