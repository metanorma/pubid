module Pubid::Bsi
  RSpec.describe Identifier do
    subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    context "BS 0" do
      let(:pubid) { "BS 0" }

      it_behaves_like "converts pubid to pubid"
    end

    context "BS 7121-3:2017" do
      let(:pubid) { "BS 7121-3:2017" }

      it_behaves_like "converts pubid to pubid"
    end
  end
end
