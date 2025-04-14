
module Pubid::Iso
  RSpec.describe Identifier do
    # subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    describe "creating new recommendation identifier" do
      subject { described_class.create(**{ number: number, type: :r }.merge(params)) }
      let(:number) { 123 }
      let(:params) { {} }

      it "renders default publisher" do
        expect(subject.to_s).to eq("ISO/R #{number}")
      end

      context "identifier with addendum" do
        let(:params) { { addendum: { number: 1, year: 1969 } } }

        it "render identifier with addendum" do
          expect(subject.to_s).to eq("ISO/R #{number}/Add 1:1969")
        end

        context "identifier with addendum without year" do
          let(:params) { { addendum: { number: 1 } } }

          it "render identifier with addendum" do
            expect(subject.to_s).to eq("ISO/R #{number}/Add 1")
          end
        end
      end
    end
  end
end
