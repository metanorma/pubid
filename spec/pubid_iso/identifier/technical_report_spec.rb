module Pubid::Iso
  module Identifier
    RSpec.describe TechnicalReport do
      subject { described_class.new(**{ number: number }.merge(params)) }
      let(:number) { 123 }
      let(:params) { {} }

      it "renders document type" do
        expect(subject.to_s).to eq("ISO/TR #{number}")
      end

      it "returns type" do
        expect(subject.type).to eq(:tr)
      end

      it "renders URN" do
        expect(subject.urn).to eq("urn:iso:std:iso:tr:#{number}")
      end
    end
  end
end
