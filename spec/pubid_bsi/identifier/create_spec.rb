module Pubid::Bsi
  RSpec.describe Identifier do
    describe "creating new identifier" do
      subject { described_class.create(**{ number: number }.merge(params)) }
      let(:number) { 123 }
      let(:params) { {} }

      it "renders default publisher" do
        expect(subject.to_s).to eq("BS #{number}")
      end

      context "with part and year" do
        let(:params) { { part: 1, year: 1999 } }

        it "renders identifier with part and year" do
          expect(subject.to_s).to eq("BS #{number}-1:1999")
        end
      end
    end
  end
end
