module Pubid::Itu
  RSpec.describe Identifier do
    subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    context "ITU-T T.4" do
      let(:pubid) { "ITU-T T.4" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-T L.163" do
      let(:pubid) { "ITU-T L.163" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ITU-R V.574-5" do
      let(:pubid) { "ITU-R V.574-5" }

      it_behaves_like "converts pubid to pubid"
    end
  end
end
