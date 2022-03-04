require "parslet/rig/rspec"

RSpec.describe PubidIso::Parser do
  subject { described_class.new }

  context "ISO 4" do
    let(:pubid) { "ISO 4" }

    it "parses document id" do
      expect(subject.parse(pubid)).to eq(number: "4")
    end
  end

  context "iso-sample-identifiers-v2.txt" do
    it "parses identifiers from iso-sample-identifiers-v2.txt" do
      f = open("spec/fixtures/iso-sample-identifiers-v2.txt")
      f.readlines.each do |pub_id|
        expect(subject).to parse(pub_id.chomp)
      end
    end
  end
end
