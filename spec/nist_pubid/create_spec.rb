module Pubid::Nist
  RSpec.describe Identifier do
    describe "creating new identifier" do
      subject { described_class.create(**{ number: number, serie: serie }.merge(params)).to_s }
      let(:number) { 123 }
      let(:params) { {} }
      let(:serie) { "SP" }

      it "renders default publisher" do
        expect(subject).to eq("NIST SP #{number}")
      end
    end
  end
end
