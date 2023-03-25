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

      context "PAS type" do
        let(:params) { { type: :pas } }

        it "renders PAS identifier" do
          expect(subject.to_s).to eq("PAS #{number}")
        end
      end

      context "PD type" do
        let(:params) { { type: :pd } }

        it "renders PD identifier" do
          expect(subject.to_s).to eq("PD #{number}")
        end
      end

      context "Flex type" do
        let(:params) { { type: :flex, edition: "3.0" } }

        it "renders Flex identifier" do
          expect(subject.to_s).to eq("BSI Flex #{number} v3.0")
        end
      end

      context "supplements" do
        let(:params) { { supplement: Identifier.create(type: type, number: 1, year: 1999) } }

        context "amendment" do
          let(:type) { :amd }

          it "renders amendment" do
            expect(subject.to_s).to eq("BS #{number}+A1:1999")
          end
        end

        context "corrigendum" do
          let(:type) { :cor }

          it "renders amendment" do
            expect(subject.to_s).to eq("BS #{number}+C1:1999")
          end
        end
      end
    end
  end
end
