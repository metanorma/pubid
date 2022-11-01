module Pubid::Iso
  RSpec.describe Corrigendum do
    let(:pubid_corrigendum) { "/Cor 1:2009" }

    describe "#render" do
      subject { described_class.new(number: 1, year: 2009, typed_stage: "Cor") }

      it { expect(subject.render_pubid).to eq(pubid_corrigendum) }

      context "when corrigendum has stage" do
        subject { described_class.new(number: 1, year: 2009, typed_stage: "CD Cor") }
        let(:pubid_corrigendum) { "/CD Cor 1:2009" }
        let(:urn_corrigendum) { ":stage-draft:cor:2009:v1" }

        it { expect(subject.render_pubid).to eq(pubid_corrigendum) }
        it { expect(subject.render_urn).to eq(urn_corrigendum) }
      end
    end
  end
end
