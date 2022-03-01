RSpec.describe PubidIso::Identifier do
  subject { described_class.parse(pubid) }

  context "ISO 4" do
    let(:pubid) { "ISO 4" }

    it "returns correct URN" do
      expect(subject.urn.to_s).to eq("urn:iso:std:iso:4")
    end
  end

  context "ISO/IEC FDIS 7816-6" do
    let(:pubid) { "ISO/IEC FDIS 7816-6" }

    it "returns correct URN" do
      expect(subject.urn.to_s).to eq("urn:iso:std:iso-iec:7816:-6:stage-50.00")
    end
  end
end
