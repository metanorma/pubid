RSpec.describe PubidIso::Parser do
  subject { described_class.new.parse(pubid) }

  context "ISO 4" do
    let(:pubid) { "ISO 4" }

    it "parses document id" do
      expect(subject).to eq(number: "4")
    end
  end
end
