module Pubid::Cen
  RSpec.describe Identifier do
    describe "creating new identifier" do
      subject { described_class.create(**{ number: number }.merge(params)) }
      let(:number) { 123 }
      let(:params) { {} }

      it "renders default publisher" do
        expect(subject.to_s).to eq("EN #{number}")
      end

      context "with part and year" do
        let(:params) { { part: 1, year: 1999 } }

        it "renders identifier with part and year" do
          expect(subject.to_s).to eq("EN #{number}-1:1999")
        end

        context "with subpart" do
          let(:params) { { part: "1-2", year: 1999 } }

          it "renders identifier with part and year" do
            expect(subject.to_s).to eq("EN #{number}-1-2:1999")
          end
        end
      end

      context "with type" do
        let(:params) { { type: :ts } }

        it "renders identifier with type" do
          expect(subject.to_s).to eq("EN/TS #{number}")
        end
      end

      context "with publisher" do
        let(:params) { { publisher: "CLC" } }

        it "renders identifier with language" do
          expect(subject.to_s).to eq("CLC #{number}")
        end
      end

      context "draft" do
        let(:params) { { stage: "pr" } }

        it "renders draft stage" do
          expect(subject.to_s).to eq("prEN #{number}")
        end

        context "final draft" do
          let(:params) { { stage: "Fpr" } }

          it "renders final draft stage" do
            expect(subject.to_s).to eq("FprEN #{number}")
          end
        end
      end
    end
  end
end
