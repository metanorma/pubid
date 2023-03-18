module Pubid::Iso
  RSpec.describe Identifier do
    describe "#parse_from_title" do
      subject { described_class.parse_from_title(title) }
      let(:title) { "#{pubid} Geographic information — Metadata — Part 1: Fundamentals" }
      let(:pubid) { "ISO 19115-1:2014" }

      it "extracts pubid from title" do
        expect(subject.to_s).to eq(pubid)
      end

      context "when title is not parsable" do
        let(:pubid) { "WRONG_PUBLISHER 1:2345" }

        it "raises an error" do
          expect { subject }.to raise_exception(Errors::ParseError)
        end
      end
    end

    describe "#resolve_identifier" do
      subject { described_class.resolve_identifier({ number: 1, publisher: "ISO", type: type, stage: typed_stage }) }
      let(:type) { nil }
      let(:typed_stage) { nil }

      context "when DTR" do
        let(:typed_stage) { "DTR" }

        it { is_expected.to a_kind_of(Identifier::TechnicalReport) }
        it { expect(subject.typed_stage).to eq(:dtr) }
      end

      context "when DTS" do
        let(:typed_stage) { "DTS" }

        it { is_expected.to a_kind_of(Identifier::TechnicalSpecification) }
        it { expect(subject.typed_stage).to eq(:dts) }
      end

      context "when no type or typed stage" do
        it { is_expected.to a_kind_of(Identifier::InternationalStandard) }
      end
    end
  end
end
