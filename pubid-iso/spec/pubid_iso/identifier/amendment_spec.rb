module Pubid::Iso
  module Identifier
    RSpec.describe Amendment do
      context "when create amendment identifier" do
        let(:base) { Identifier.create(**{ number: number, edition: 1 }.merge(params)) }

        subject { described_class.new(number: 1, base: base, **amendment_params) }
        let(:params) { { year: year } }
        let(:number) { 123 }

        let(:amendment_params) { {} }
        let(:year) { 1999 }
        let(:stage) { nil }


        it "renders amendment with base document" do
          expect(subject.to_s).to eq("ISO 123:1999/Amd 1")
          expect(subject.urn).to eq("urn:iso:std:iso:123:ed-1:amd:1:v1")
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
          let(:stage) { Identifier.build_stage(abbr: :DIS) }

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
            let(:stage) { Identifier.build_stage(abbr: :CD) }

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

          context "when stage is a harmonized code" do
            context "when stage is 50.00" do
              let(:stage) { "50.00" }

              it "renders long stage and amendment" do
                expect(subject.to_s).to eq("ISO #{number}:1999/FDAM 1")
              end
            end

            context "when stage is 60.00" do
              let(:stage) { "60.00" }

              it "renders long stage and amendment" do
                expect(subject.to_s).to eq("ISO #{number}:1999/Amd 1")
              end
            end

            context "when stage is 60.60" do
              let(:stage) { "60.60" }

              it "renders long stage and amendment" do
                expect(subject.to_s).to eq("ISO #{number}:1999/Amd 1")
              end
            end
          end
        end
      end
    end
  end
end
