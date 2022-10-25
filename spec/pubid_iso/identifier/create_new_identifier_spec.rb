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
          let(:params) { { stage: stage, type: :tr } }

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

          context "at stage PRF" do
            let(:stage) { Stage.new(harmonized_code: "50.00", abbr: :PRF) }

            it "renders separate stage for PubID" do
              expect(subject.to_s(with_prf: true)).to eq("ISO/PRF #{number}")
            end

            it "renders separate numeric stage for URN" do
              expect(subject.urn).to eq("urn:iso:std:iso:#{number}:stage-50.00")
            end
          end

          context "at stage FDIS" do
            let(:stage) { :fdis }

            it "renders separate stage for PubID" do
              expect(subject.to_s).to eq("ISO/FDIS #{number}")
            end

            it "renders separate numeric stage for URN" do
              expect(subject.urn).to eq("urn:iso:std:iso:#{number}:stage-50.00")
            end
          end

        end

      end

      context "when TS type" do
        let(:params) { { stage: stage } }

        context "when DTS typed stage" do
          let(:stage) { "DTS" }

          it "renders correct identifier" do
            expect(subject.to_s).to eq("ISO/DTS #{number}")
          end
        end

        context "when FDTS typed stage" do
          let(:stage) { "FDTS" }

          it "renders correct identifier" do
            expect(subject.to_s).to eq("ISO/FDTS #{number}")
          end
        end
      end

      context "when TR type" do
        let(:params) { { stage: stage } }

        context "when DTR typed stage" do
          let(:stage) { "DTR" }

          it "renders correct identifier" do
            expect(subject.to_s).to eq("ISO/DTR #{number}")
          end
        end

        context "when FDTR typed stage" do
          let(:stage) { "FDTR" }

          it "renders correct identifier" do
            expect(subject.to_s).to eq("ISO/FDTR #{number}")
          end
        end
      end

      context "when PAS type" do
        let(:params) { { type: :pas, stage: stage } }

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

        context "with DPAS typed stage" do
          let(:params) { { stage: stage } }
          let(:stage) { "DPAS" }

          it "renders correct identifier" do
            expect(subject.to_s).to eq("ISO/DPAS #{number}")
          end
        end

        context "with FDIS typed stage" do
          let(:stage) { :fdis }

          it "raises an error" do
            expect { subject }.to raise_exception(Errors::StageInvalidError)
          end
        end
      end

      context "when have typed stage" do
        let(:params) { { stage: typed_stage } }
        let(:typed_stage) { "DTR" }

        it "assigns typed stage" do
          expect(subject.typed_stage).to be_a(TypedStage)
        end

        it "renders correct identifier" do
          expect(subject.to_s).to eq("ISO/DTR #{number}")
        end

        it "has related harmonized stage codes assigned" do
          expect(subject.typed_stage.stage.harmonized_code.stages)
            .to eq(%w[40.00 40.20 40.60 40.92 40.93 50.00 50.20 50.60 50.92])
        end

        it "renders document with typed stage" do
          expect(subject.to_s).to eq("ISO/DTR 123")
        end
      end

      context "when create amendment identifier" do
        let(:base) { described_class.new(**{ number: number }.merge(params)) }

        subject { described_class.new(type: :amd, number: 1, base: base, **amendment_params) }
        let(:params) { { year: year } }

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
            let(:stage) { "DAmd" }

            it "renders long stage and amendment" do
              expect(subject.to_s).to eq("ISO #{number}:1999/DAmd 1")
            end

            it "renders short stage and amendment" do
              expect(subject.to_s(format: :ref_num_short)).to eq("ISO #{number}:1999/DAM 1")
            end

            context "when stage is a symbol" do
              let(:stage) { :damd }

              it "renders long stage and amendment" do
                expect(subject.to_s).to eq("ISO #{number}:1999/DAmd 1")
              end
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

      context "when create corrigendum identifier" do
        let(:base) { described_class.new(**{ number: number }.merge(params)) }

        subject { described_class.new(type: :cor, number: 1, base: base, **corrigendum_params) }

        let(:params) { { year: 1999 } }

        context "when corrigendum with stage" do
          let(:corrigendum_params) { { stage: stage } }

          context "with DCor stage" do
            let(:stage) { :dcor }
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
        let(:params) { { iteration: 1, type: type } }

        context "and IS type" do
          let(:type) { :is }

          it "raises the error" do
            expect { subject }.to raise_exception(Errors::IsStageIterationError)
          end
        end

        context "without type" do
          let(:type) { nil }

          it "raises the error" do
            expect { subject }.to raise_exception(Errors::IterationWithoutStageError)
          end
        end
      end

      context "when document have DIR type" do
        let(:params) { { type: :dir } }

        it "render DIR document" do
          expect(subject.to_s).to eq("ISO DIR #{number}")
        end

        context "when have language parameter" do
          let(:params) { { type: :dir, language: "en" } }

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
                                                                     typed_stage: :damd)]).to_s(format: format)
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
