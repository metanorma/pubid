module Pubid::Iso
  RSpec.describe Identifier do
    subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    describe "creating new identifier" do
      subject { described_class.new(**{ number: number }.merge(params)) }
      let(:number) { 123 }
      let(:params) { {} }

      it "renders default publisher" do
        expect(subject.to_s).to eq("ISO #{number}")
      end

      context "when have joint document" do
        let(:params) { { joint_document: "IDF #{number}" } }

        it "renders correct identifier" do
          expect(subject.to_s).to eq("ISO #{number}|IDF #{number}")
        end
      end

      context "when have stage" do
        let(:params) { { stage: stage } }
        let(:stage) { Pubid::Iso::Stage.new(abbr: :WD) }

        it "has harmonized stage assigned" do
          expect(subject.stage.harmonized_code)
            .to eq(Pubid::Iso::HarmonizedStageCode.new("20", "20"))
        end

        it "renders separate stage for PubID" do
          expect(subject.to_s).to eq("ISO/WD #{number}")
        end

        it "renders stage for URN" do
          expect(subject.urn).to eq("urn:iso:std:iso:#{number}:stage-20.20")
        end

        context "when have document type" do
          let(:params) { { stage: stage, type: "TR" } }

          it "renders stage first" do
            expect(subject.to_s).to eq("ISO/WD TR #{number}")
          end
        end

        context "when stage is a symbol" do
          let(:params) { { stage: :WD } }

          it "has harmonized stage assigned" do
            expect(subject.stage.harmonized_code)
              .to eq(Pubid::Iso::HarmonizedStageCode.new("20", "20"))
          end
        end

        context "when stage is a string" do
          let(:params) { { stage: "WD" } }

          it "has harmonized stage assigned" do
            expect(subject.stage.harmonized_code)
              .to eq(Pubid::Iso::HarmonizedStageCode.new("20", "20"))
          end
        end

        context "when stage is a code" do
          let(:params) { { stage: "40.60" } }

          it "has harmonized stage assigned" do
            expect(subject.stage.harmonized_code)
              .to eq(Pubid::Iso::HarmonizedStageCode.new("40", "60"))
          end
        end

        context "when have harmonized code and abbr" do
          let(:stage) { Stage.new(harmonized_code: "50.00", abbr: :PRF) }

          it "renders separate stage for PubID" do
            expect(subject.to_s(with_prf: true)).to eq("ISO/PRF #{number}")
          end

          it "renders separate numeric stage for URN" do
            expect(subject.urn).to eq("urn:iso:std:iso:#{number}:stage-50.00")
          end
        end
      end

      context "when TS type" do
        let(:params) { { type: "TS", stage: stage } }

        context "when DIS stage" do
          let(:stage) { :DIS }

          it "renders correct identifier" do
            expect(subject.to_s).to eq("ISO/DTS #{number}")
          end
        end

        context "when FDIS stage" do
          let(:stage) { :FDIS }

          it "renders correct identifier" do
            expect(subject.to_s).to eq("ISO/FDTS #{number}")
          end
        end
      end

      context "when TR type" do
        let(:params) { { type: "TR", stage: stage } }

        context "when DIS stage" do
          let(:stage) { :DIS }

          it "renders correct identifier" do
            expect(subject.to_s).to eq("ISO/DTR #{number}")
          end
        end

        context "when FDIS stage" do
          let(:stage) { :FDIS }

          it "renders correct identifier" do
            expect(subject.to_s).to eq("ISO/FDTR #{number}")
          end
        end
      end

      context "when PAS type" do
        let(:params) { { type: "PAS", stage: stage } }

        context "with WD stage" do
          let(:stage) { :WD }

          it "renders correct identifier" do
            expect(subject.to_s).to eq("ISO/WD PAS #{number}")
          end
        end

        context "with CD stage" do
          let(:stage) { :CD }

          it "renders correct identifier" do
            expect(subject.to_s).to eq("ISO/CD PAS #{number}")
          end
        end

        context "with DIS stage" do
          let(:stage) { :DIS }

          it "renders correct identifier" do
            expect(subject.to_s).to eq("ISO/DPAS #{number}")
          end
        end

        context "with IS stage" do
          let(:stage) { :IS }

          it "renders correct identifier" do
            expect(subject.to_s).to eq("ISO/PAS #{number}")
          end
        end

        context "with FDIS stage" do
          let(:stage) { :FDIS }

          it "raises an error" do
            expect { subject }.to raise_exception(Errors::StageInvalidError)
          end
        end
      end

      context "when create document with amendment" do
        let(:params) { { year: year, amendments: [Pubid::Iso::Amendment.new(number: 1, **amendment_params)] } }
        let(:amendment_params) { { } }
        let(:year) { 1999 }
        let(:stage) { nil }

        context "when provide an array of hashes for amendments parameter instead of Pubid::Iso::Amendment" do
          subject { described_class.parse(**{ number: number }.merge(params)) }

          let(:params) { { year: year, amendments: [{ number: 1 }] } }

          it "renders document with amendment year" do
            expect(subject.to_s).to eq("ISO 123:1999/Amd 1")
          end
        end

        context "when document don't have year" do
          let(:year) { nil }

          it "raises an error" do
            expect { subject }.to raise_exception(Errors::SupplementWithoutYearOrStageError)
          end

          context "but have a stage" do
            let(:params) { { year: year, stage: :FDIS, amendments: [Pubid::Iso::Amendment.new(number: 1, **amendment_params)] } }

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

          context "when IS stage" do
            let(:stage) { Stage.new(abbr: "IS") }

            it "should not render IS stage" do
              expect(subject.to_s).to eq("ISO 123:1999/Amd 1")
            end
          end

          context "when DIS stage" do
            let(:stage) { Stage.new(abbr: :DIS) }

            context "when stage is a symbol" do
              let(:stage) { :DIS }

              it "renders long stage and amendment" do
                expect(subject.to_s).to eq("ISO #{number}:1999/DAmd 1")
              end
            end

            it "renders long stage and amendment" do
              expect(subject.to_s).to eq("ISO #{number}:1999/DAmd 1")
            end

            it "renders short stage and amendment" do
              expect(subject.to_s(format: :ref_num_short)).to eq("ISO #{number}:1999/DAM 1")
            end
          end

          context "when CD stage" do
            let(:stage) { Stage.new(abbr: :CD) }

            it "renders long stage and amendment" do
              expect(subject.to_s(format: :ref_num_long)).to eq("ISO #{number}:1999/CD Amd 1")
            end

            it "renders short stage and amendment" do
              expect(subject.to_s(format: :ref_num_short)).to eq("ISO #{number}:1999/CDAM 1")
            end
          end

          context "when stage is a code" do
            let(:stage) { "40.60" }

            it "renders long stage and amendment" do
              expect(subject.to_s).to eq("ISO #{number}:1999/DAmd 1")
            end
          end
        end
      end

      context "when create document with corrigendum" do
        let(:params) { { year: 1999, amendments: [Corrigendum.new(number: 1, **corrigendum_params)] } }

        context "when corrigendum with stage" do
          let(:corrigendum_params) { { stage: stage } }

          context "with IS stage" do
            let(:stage) { Stage.new(abbr: "IS") }

            it "should not render IS stage" do
              expect(subject.to_s).to eq("ISO 123:1999/Cor 1")
            end
          end

          context "with DIS stage" do
            let(:stage) { Stage.new(abbr: :DIS) }
            it "renders long stage and corrigendum" do
              expect(subject.to_s).to eq("ISO #{number}:1999/DCor 1")
            end

            it "renders short stage and corrigendum" do
              expect(subject.to_s(format: :ref_num_short)).to eq("ISO #{number}:1999/DCOR 1")
            end
          end
        end
      end

      context "when create identifier with iteration" do
        let(:params) { { iteration: 1, stage: stage } }

        context "and IS stage" do
          let(:stage) { Stage.new(abbr: "IS") }

          it "raises the error" do
            expect { subject }.to raise_exception(Errors::IsStageIterationError)
          end
        end

        context "without stage" do
          let(:stage) { nil }

          it "raises the error" do
            expect { subject }.to raise_exception(Errors::IterationWithoutStageError)
          end
        end
      end

      context "when document have DIR type" do
        let(:params) { { type: "DIR" } }

        it "render DIR document" do
          expect(subject.to_s).to eq("ISO DIR #{number}")
        end

        context "when have language parameter" do
          let(:params) { { type: "DIR", language: "en" } }

          it "render DIR document with language" do
            expect(subject.to_s(format: :ref_num_long)).to eq("ISO DIR #{number}(en)")
          end
        end
      end

      context "when another publisher" do
        let(:params) { { publisher: "IEC" } }

        it "render with another publisher" do
          expect(subject.to_s).to eq("IEC #{number}")
        end
      end

      describe "predefined formats" do
        subject do
          described_class.new(number: number, year: 2019, language: "en",
                              amendments: [Pubid::Iso::Amendment.new(number: 1, year: "2021",
                                                                     stage: Stage.new(abbr: :DIS))]).to_s(format: format)
        end
        let(:number) { 123 }

        context "when ref_num_short format" do
          let(:format) { :ref_num_short }

          it { expect(subject).to eq("ISO #{number}:2019/DAM 1:2021(E)") }
        end

        context "when ref_num_long format" do
          let(:format) { :ref_num_long }

          it { expect(subject.to_s).to eq("ISO #{number}:2019/DAmd 1:2021(en)") }
        end

        context "when ref_dated format" do
          let(:format) { :ref_dated }

          it { expect(subject.to_s).to eq("ISO #{number}:2019/DAM 1:2021") }
        end

        context "when ref_dated_long format" do
          let(:format) { :ref_dated_long }

          it { expect(subject.to_s).to eq("ISO #{number}:2019/DAmd 1:2021") }
        end

        context "when ref_undated format" do
          let(:format) { :ref_undated }

          it { expect(subject.to_s).to eq("ISO #{number}:2019/DAM 1") }
        end

        context "when ref_undated_long" do
          let(:format) { :ref_undated_long }

          it { expect(subject.to_s).to eq("ISO #{number}:2019/DAmd 1") }
        end
      end
    end
  end
end
