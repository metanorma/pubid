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

  context "IWA 8:2009" do
    let(:pubid) { "IWA 8:2009" }
    let(:urn) { "urn:iso:std:iwa:8" }

    it_behaves_like "converts pubid to urn"
  end

  context "ISO/IEC TR 24754-2:2011" do
    let(:pubid) { "ISO/IEC TR 24754-2:2011" }
    let(:urn) { "urn:iso:std:iso-iec:tr:24754:-2" }

    it_behaves_like "converts pubid to urn"
  end

  context "FprISO 105-A03" do
    let(:pubid) { "FprISO 105-A03" }
    let(:urn) { "urn:iso:std:iso:105:-A03:stage-50.00" }

    it_behaves_like "converts pubid to urn"
  end

  context "ISO/IEC/IEEE 26512" do
    let(:pubid) { "ISO/IEC/IEEE 26512" }
    let(:urn) { "urn:iso:std:iso-iec-ieee:26512" }

    it_behaves_like "converts pubid to urn"
  end

  context "ISO/IEC 30142 ED1" do
    let(:pubid) { "ISO/IEC 30142 ED1" }
    let(:urn) { "urn:iso:std:iso-iec:30142:ed-1" }

    it_behaves_like "converts pubid to urn"
  end

  context "ISO 22610:2006 Ed" do
    let(:pubid) { "ISO 22610:2006 Ed" }
    let(:urn) { "urn:iso:std:iso:22610:ed-1" }

    it_behaves_like "converts pubid to urn"
  end

  context "ISO 17121:2000 Ed 1" do
    let(:pubid) { "ISO 17121:2000 Ed 1" }
    let(:urn) { "urn:iso:std:iso:17121:ed-1" }

    it_behaves_like "converts pubid to urn"
  end

  context "ISO 11553-1 Ed.2" do
    let(:pubid) { "ISO 11553-1 Ed.2" }
    let(:urn) { "urn:iso:std:iso:11553:-1:ed-2" }

    it_behaves_like "converts pubid to urn"
  end
end
