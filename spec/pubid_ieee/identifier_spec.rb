RSpec.describe Pubid::Ieee::Identifier do
  subject { described_class.parse(original) }

  shared_examples "converts pubid to pubid" do
    it "converts pubid to pubid" do
      expect(subject.to_s).to eq(pubid)
    end
  end

  context "IEEE No 142-1956" do
    let(:original) { "IEEE No 142-1956" }
    let(:pubid) { "IEEE No 142-1956" }

    it_behaves_like "converts pubid to pubid"
  end
end
