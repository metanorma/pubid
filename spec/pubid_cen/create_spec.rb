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
        context "Technical Specification" do
          let(:params) { { type: :ts } }

          it "renders identifier with type" do
            expect(subject.to_s).to eq("EN/TS #{number}")
          end
        end

        context "European Norm" do
          let(:params) { { type: :en } }

          it "renders identifier with type" do
            expect(subject.to_s).to eq("EN #{number}")
          end
        end

        context "CEN Workshop Agreement" do
          let(:params) { { type: :cwa } }

          it "renders identifier with type" do
            expect(subject.to_s).to eq("CWA #{number}")
          end
        end

        context "Harmonization Document" do
          let(:params) { { type: :hd } }

          it "renders identifier with type" do
            expect(subject.to_s).to eq("HD #{number}")
          end
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

      context "incorporated supplements" do
        let(:params) { { incorporated_supplements: [Identifier.create(type: type, number: 1, year: 1999)] } }

        context "amendment" do
          let(:type) { :amd }

          it "renders incorporated amendment" do
            expect(subject.to_s).to eq("EN #{number}+A1:1999")
          end
        end

        context "corrigendum" do
          let(:type) { :cor }

          it "renders incorporated corrigendum" do
            expect(subject.to_s).to eq("EN #{number}+AC1:1999")
          end
        end
      end

      context "supplement" do
        subject { described_class.create(**{ number: number }.merge(params)) }

        let(:params) { { type: type, number: supplement_number, year: 1999, base: Identifier.create(number: number) } }
        let(:supplement_number) { 1 }

        context "amendment" do
          let(:type) { :amd }

          it "renders amendment" do
            expect(subject.to_s).to eq("EN #{number}/A1:1999")
          end
        end

        context "corrigendum" do
          let(:type) { :cor }

          it "renders corrigendum" do
            expect(subject.to_s).to eq("EN #{number}/AC1:1999")
          end

          context "without number" do
            let(:supplement_number) { nil }

            it "renders corrigendum" do
              expect(subject.to_s).to eq("EN #{number}/AC:1999")
            end
          end
        end
      end
    end
  end
end
