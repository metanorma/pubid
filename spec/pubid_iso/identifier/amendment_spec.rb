module Pubid::Iso
  module Identifier
    RSpec.describe Amendment do
      context "when create amendment identifier" do
        let(:base) { Identifier::Base.create(**{ number: number }.merge(params)) }

        subject { described_class.new(number: 1, base: base, **amendment_params) }
        let(:params) { { year: year } }
        let(:number) { 123 }

        let(:amendment_params) { {} }
        let(:year) { 1999 }
        let(:stage) { nil }


        it "renders amendment with base document" do
          expect(subject.to_s).to eq("ISO 123:1999/Amd 1")
        end

        context "when document don't have year" do
          let(:year) { nil }

          it "raises an error" do
            expect { subject }.to raise_exception(Errors::SupplementWithoutYearOrStageError)
          end

          context "but have a stage" do
            let(:params) { { year: year, stage: :fdis } }

            it "don't raise an error" do
              expect { subject }.not_to raise_exception
            end
          end
        end

        context "when amendment has a year" do
          let(:amendment_params) { { year: 2017 } }

          it "renders document with amendment year" do
            expect(subject.to_s).to eq("ISO 123:1999/Amd 1:2017")
          end
        end

        context "when amendment without year" do
          let(:amendment_params) { {} }

          it "renders document with amendment year" do
            expect(subject.to_s).to eq("ISO 123:1999/Amd 1")
          end
        end

        context "when amendment with stage" do
          let(:amendment_params) { { stage: stage } }
          let(:stage) { Stage.new(abbr: :DIS) }

          context "when DAmd typed stage" do
            let(:stage) { "DAM" }

            it "renders long stage and amendment" do
              expect(subject.to_s).to eq("ISO #{number}:1999/DAM 1")
            end

            it "renders short stage and amendment" do
              expect(subject.to_s(format: :ref_num_short)).to eq("ISO #{number}:1999/DAM 1")
            end

            context "when stage is a symbol" do
              let(:stage) { :damd }

              it "renders long stage and amendment" do
                expect(subject.to_s).to eq("ISO #{number}:1999/DAM 1")
              end
            end
          end

          context "when CD stage" do
            let(:stage) { Stage.new(abbr: :CD) }

            it "renders long stage and amendment" do
              expect(subject.to_s(format: :ref_num_long)).to eq("ISO #{number}:1999/CD Amd 1")
            end

            it "renders short stage and amendment" do
              expect(subject.to_s(format: :ref_num_short)).to eq("ISO #{number}:1999/CD Amd 1")
            end
          end

          context "when stage is a code" do
            let(:stage) { "40.60" }

            it "renders long stage and amendment" do
              expect(subject.to_s).to eq("ISO #{number}:1999/DAM 1")
            end
          end
        end
      end
    end
  end
end
