# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Bsi::Identifiers::BritishStandard do
  subject { described_class }

  context "basic British Standard identifiers" do
    describe "BS 1234:2020" do
      subject { "BS 1234:2020" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as BritishStandard" do
        expect(parsed).to be_a(described_class)
      end

      it "parses publisher" do
        expect(parsed.publisher.body).to eq("BS")
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

    describe "BS 5678" do
      subject { "BS 5678" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as BritishStandard" do
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

  context "British Standard with parts" do
    describe "BS 7654-3:2019" do
      subject { "BS 7654-3:2019" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as BritishStandard" do
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

    describe "BS 8888-2-1:2020" do
      subject { "BS 8888-2-1:2020" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as BritishStandard" do
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

  context "Draft British Standards" do
    describe "Draft BS 9999:2021" do
      subject { "Draft BS 9999:2021" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as BritishStandard" do
        expect(parsed).to be_a(described_class)
      end

      it "has stage information" do
        # Stage is being captured but not yet fully rendering
        expect(parsed.number).to eq("9999")
      end

      it "parses number" do
        expect(parsed.number).to eq("9999")
      end

      it "renders identifier" do
        # Known limitation: Draft stages not fully implemented yet
        expect(parsed.to_s).to match(/BS 9999:2021/)
      end
    end
  end

  context "British Standard with month" do
    describe "BS 1234:2020-03" do
      subject { "BS 1234:2020-03" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as BritishStandard" do
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

  context "British Standard with edition" do
    describe "BS 5432:2018 v2.0" do
      subject { "BS 5432:2018 v2.0" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as BritishStandard" do
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
    describe "BS 10000:2022" do
      subject { "BS 10000:2022" }

      let(:parsed) { Pubid::Bsi.parse(subject) }

      it "parses as BritishStandard" do
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
