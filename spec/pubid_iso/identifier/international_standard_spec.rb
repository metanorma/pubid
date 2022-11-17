module Pubid::Iso
  module Identifier
    RSpec.describe InternationalStandard do
      subject { described_class.new(**{ number: number }.merge(params)) }
      let(:number) { 123 }
      let(:params) { {} }

      it "renders default publisher" do
        expect(subject.to_s).to eq("ISO #{number}")
      end

      it "returns type" do
        expect(subject.type).to eq(:is)
      end

      it "renders URN" do
        expect(subject.urn).to eq("urn:iso:std:iso:#{number}")
      end
    end
  end
end
