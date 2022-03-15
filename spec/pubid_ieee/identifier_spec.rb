RSpec.describe Pubid::Ieee::Identifier do
  subject { described_class.parse(original) }

  let(:original) { pubid }

  shared_examples "converts pubid to pubid" do
    it "converts pubid to pubid" do
      expect(subject.to_s).to eq(pubid)
    end
  end

  context "IEEE No 142-1956" do
    let(:original) { "IEEE No 142-1956" }
    let(:pubid) { "IEEE 142-1956" }

    it_behaves_like "converts pubid to pubid"
  end

  context "IEEE Std 802.15.22.3-2020" do
    let(:pubid) { "IEEE Std 802.15.22.3-2020" }

    it_behaves_like "converts pubid to pubid"
  end
end
