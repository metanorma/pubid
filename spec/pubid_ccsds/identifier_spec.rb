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
  end
end
