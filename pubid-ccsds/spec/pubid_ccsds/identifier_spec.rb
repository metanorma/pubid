module Pubid::Ccsds
  RSpec.describe Identifier do
    subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    context "CCSDS 120.0-G-4" do
      let(:pubid) { "CCSDS 120.0-G-4" }

      it_behaves_like "converts pubid to pubid"
    end

    context "CCSDS A20.1-Y-1" do
      let(:pubid) { "CCSDS A20.1-Y-1" }

      it_behaves_like "converts pubid to pubid"
    end

    context "CCSDS 100.0-G-1-S" do
      let(:pubid) { "CCSDS 100.0-G-1-S" }

      it_behaves_like "converts pubid to pubid"
    end

    context "CCSDS 131.2-O-1-S Cor. 1" do
      let(:pubid) { "CCSDS 131.2-O-1-S Cor. 1" }

      it_behaves_like "converts pubid to pubid"
      it { expect(subject).to be_a(Identifier::Corrigendum) }
    end

    context "CCSDS 551.1-O-2 - Russian Translated" do
      let(:original) { "CCSDS 551.1-O-2 - Russian Translated" }
      let(:pubid) { "CCSDS 551.1-O-2 - Russian Translated" }

      it_behaves_like "converts pubid to pubid"
    end

    context "CCSDS 401.0-B-S" do
      let(:pubid) { "CCSDS 401.0-B-S" }

      it_behaves_like "converts pubid to pubid"
    end

    context "CCSDS 912.1-B-2-S Cor.1" do
      let(:pubid) { "CCSDS 912.1-B-2-S Cor. 1" }

      it_behaves_like "converts pubid to pubid"
    end

    context "CCSDS A01.2-Y-4.1-S" do
      let(:pubid) { "CCSDS A01.2-Y-4.1-S" }

      it_behaves_like "converts pubid to pubid"
    end

    describe "parse identifiers from examples files" do
      context "parses IEC identifiers from active-publications.txt" do
        let(:examples_file) { "active-publications.txt" }

        it_behaves_like "parse identifiers from file"
      end

      context "parses IEC identifiers from historical-publications.txt" do
        let(:examples_file) { "historical-publications.txt" }

        it_behaves_like "parse identifiers from file"
      end
    end
  end
end
