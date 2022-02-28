RSpec.describe PubidIso::Parser do
  subject { described_class.new.parse(original_pubid) }

  context "ISO 4" do
    let(:original_pubid) { "ISO 4" }

    it "parses document id" do
      expect(subject).to eq("ISO 4")
    end
  end
end
