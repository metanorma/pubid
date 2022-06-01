RSpec.describe Pubid::Iso::Amendment do
  let(:pubid) { "ISO 6709:2008#{pubid_amendment}" }
  let(:pubid_amendment) { "/Amd 1:2009" }

  describe "#render" do
    subject { Pubid::Iso::Identifier.parse(pubid).amendment }

    it { expect(subject.render_pubid).to eq(pubid_amendment) }

    context "when amendment has stage" do
      let(:pubid_amendment) { "/CD Amd 1:2009" }
      let(:urn_amendment) { ":stage-30.00:amd:2009:v1" }

      it { expect(subject.render_pubid).to eq(pubid_amendment) }
      it { expect(subject.render_urn).to eq(urn_amendment) }
    end
  end
end
