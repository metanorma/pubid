module Pubid::Iso
  RSpec.describe Identifier::Base do
    subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    context "ISO TC 184/SC 4 N1110" do
      let(:pubid) { "ISO/TC 184/SC 4 N1110" }
      let(:urn) { "urn:iso:doc:iso:tc:184:sc:4:1110" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC JTC 1/SC 32 N1001" do
      let(:pubid) { "ISO/IEC JTC 1/SC 32 N1001" }
      let(:urn) { "urn:iso:doc:iso-iec:jtc:1:sc:32:1001" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/TC 184/SC/QC 4 N265" do
      let(:pubid) { "ISO/TC 184/SC/QC 4 N265" }
      let(:urn) { "urn:iso:doc:iso:tc:184:sc:4:qc:265" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/TC 46 N 3064" do
      let(:original) { "ISO/TC 46 N 3064" }
      let(:pubid) { "ISO/TC 46 N3064" }
      let(:urn) { "urn:iso:doc:iso:tc:46:3064" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/TC 184/SC 4/WG 12 N10897" do
      let(:original) { "ISO/TC 184/SC 4/WG 12 N10897" }
      let(:pubid) { "ISO/TC 184/SC 4/WG 12 N10897" }
      let(:urn) { "urn:iso:doc:iso:tc:184:sc:4:wg:12:10897" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"

      it do
        expect(subject.scnumber).to eq("4")
        expect(subject.wgnumber).to eq("12")
        expect(subject.tcnumber).to eq("184")
        expect(subject.number).to eq("10897")
      end
    end

    context "ISO/TC 154/WG 5 N152" do
      let(:original) { "ISO/TC 154/WG 5 N152" }
      let(:pubid) { "ISO/TC 154/WG 5 N152" }
      let(:urn) { "urn:iso:doc:iso:tc:154:wg:5:152" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/TMB/DMT 154/WG 5 N152" do
      let(:original) { "ISO/TMB/DMT 154/WG 5 N152" }
      let(:pubid) { "ISO/DMT/TMB 154/WG 5 N152" }
      let(:urn) { "urn:iso:doc:iso:dmt:tmb:154:wg:5:152" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end
  end
end
