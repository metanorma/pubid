module Pubid::Ccsds
  RSpec.describe Identifier do
    subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    context "CCSDS 120.0-G-4" do
      let(:pubid) { "CCSDS 120.0-G-4" }

      it_behaves_like "converts pubid to pubid"
    end
  end
end
