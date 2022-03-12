RSpec.describe Pubid::Ieee::Parser do
  subject { described_class.new.parse(pubid) }

  context "IEEE No 142-1956" do
    let(:pubid) { "IEEE No 142-1956" }

    it "parses number and year" do
      expect(subject).to eq({ number: "142", year: "1956" })
    end
  end
end
