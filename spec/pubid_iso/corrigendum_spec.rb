RSpec.describe Pubid::Iso::Corrigendum do
  let(:pubid) { "ISO 6709:2008#{pubid_corrigendum}" }
  let(:pubid_corrigendum) { "/Cor 1:2009" }

  describe "#render" do
    subject { Pubid::Iso::Identifier.parse(pubid).corrigendum }

    it { expect(subject.render_pubid).to eq(pubid_corrigendum) }

    context "when corrigendum has stage" do
      let(:pubid_corrigendum) { "/CD Cor 1:2009" }
      let(:urn_corrigendum) { ":stage-30.00:cor:2009:v1" }

      it { expect(subject.render_pubid).to eq(pubid_corrigendum) }
      it { expect(subject.render_urn).to eq(urn_corrigendum) }
    end
  end
end
