RSpec.describe PubidIso::Identifier do
  subject { described_class.parse(pubid) }

  shared_examples "converts pubid to urn" do
    it "converts pubid to urn" do
      expect(subject.urn.to_s).to eq(urn)
    end
  end

  context "ISO 4" do
    let(:pubid) { "ISO 4" }
    let(:urn) { "urn:iso:std:iso:4" }

    it_behaves_like "converts pubid to urn"
  end

  context "ISO/IEC FDIS 7816-6" do
    let(:pubid) { "ISO/IEC FDIS 7816-6" }
    let(:urn) { "urn:iso:std:iso-iec:7816:-6:stage-50.00" }

    it_behaves_like "converts pubid to urn"
  end

  context "ISO/TR 30406:2017" do
    let(:pubid) { "ISO/TR 30406:2017" }
    let(:urn) { "urn:iso:std:iso:tr:30406" }

    it_behaves_like "converts pubid to urn"
  end
end
