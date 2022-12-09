module Pubid::Iso
  RSpec.describe Identifier::Base do
    subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    context "ISO DIR 1:2022" do
      let(:original) { "ISO DIR 1:2022" }
      let(:pubid) { "ISO DIR 1:2022" }
      let(:urn) { "urn:iso:doc:iso:dir:1:2022" }

      it "has DIR type" do
        expect(subject.type).to eq(:dir)
      end

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC DIR JTC 1 SUP:2021" do
      let(:original) { "ISO/IEC DIR JTC 1 SUP:2021" }
      let(:pubid) { "ISO/IEC DIR JTC 1 SUP:2021" }
      let(:urn) { "urn:iso:doc:iso-iec:dir:jtc:1:sup:2021" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC DIR IEC SUP" do
      let(:pubid) { "ISO/IEC DIR IEC SUP" }
      let(:urn) { "urn:iso:doc:iso-iec:dir:sup:iec" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC DIR 1 ISO SUP" do
      let(:pubid) { "ISO/IEC DIR 1 ISO SUP" }
      let(:urn) { "urn:iso:doc:iso-iec:dir:1:sup:iso" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC DIR 1 ISO SUP:2022" do
      let(:pubid) { "ISO/IEC DIR 1 ISO SUP:2022" }
      let(:urn) { "urn:iso:doc:iso-iec:dir:1:sup:iso:2022" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC DIR 1 ISO SUP Edition 13" do
      let(:pubid) { "ISO/IEC DIR 1 ISO SUP Edition 13" }
      let(:pubid_with_edition) { "ISO/IEC DIR 1 ISO SUP Edition 13" }
      let(:urn) { "urn:iso:doc:iso-iec:dir:1:sup:iso:ed-13" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts to pubid with edition"
    end

    context "ISO/IEC DIR 1:2022 + IEC SUP:2022" do
      let(:pubid) { "ISO/IEC DIR 1:2022 + IEC SUP:2022" }
      let(:urn) { "urn:iso:doc:iso-iec:dir:1:2022:iec:sup:2022" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC Directives Part 1" do
      let(:original) { "ISO/IEC Directives Part 1" }
      let(:pubid) { "ISO/IEC DIR 1" }
      let(:urn) { "urn:iso:doc:iso-iec:dir:1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC Directives, Part 1:2022" do
      let(:original) { "ISO/IEC Directives, Part 1:2022" }
      let(:pubid) { "ISO/IEC DIR 1:2022" }
      let(:urn) { "urn:iso:doc:iso-iec:dir:1:2022" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC Directives, IEC Supplement:2022" do
      let(:original) { "ISO/IEC Directives, IEC Supplement:2022" }
      let(:pubid) { "ISO/IEC DIR IEC SUP:2022" }
      let(:urn) { "urn:iso:doc:iso-iec:dir:sup:iec:2022" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC Directives, Part 1 -- Consolidated ISO Supplement" do
      let(:original) { "ISO/IEC Directives, Part 1 -- Consolidated ISO Supplement" }
      let(:pubid) { "ISO/IEC DIR 1 ISO SUP" }
      let(:urn) { "urn:iso:doc:iso-iec:dir:1:sup:iso" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end
  end
end
