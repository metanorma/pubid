module Pubid::Iso
  RSpec.describe Identifier do
    # subject { described_class.parse(original || pubid) }
    let(:original) { nil }

    describe "creating new identifier" do
      subject { described_class.create(**{ number: number }.merge(params)) }
      let(:number) { 123 }
      let(:params) { {} }

      it "renders default publisher" do
        expect(subject.to_s).to eq("ISO #{number}")
      end

      it "assigns default type" do
        expect(subject.type[:key]).to eq(:is)
      end

      context "when have joint document" do
        let(:params) { { joint_document: "IDF #{number}" } }

        it "renders correct identifier" do
          expect(subject.to_s).to eq("ISO #{number}|IDF #{number}")
        end
      end

      context "when have stage" do
        let(:params) { { stage: stage } }
        let(:stage) { "WD" }

        it "has harmonized stage assigned" do
          expect(subject.stage.harmonized_code)
            .to eq(Identifier.build_harmonized_stage_code("20", "20"))
        end

        it "renders separate stage for PubID" do
          expect(subject.to_s).to eq("ISO/WD #{number}")
        end

        it "renders stage for URN" do
          expect(subject.urn).to eq("urn:iso:std:iso:#{number}:stage-draft")
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
              .to eq(Identifier.build_harmonized_stage_code("20", "20"))
          end
        end

        context "when stage is a string" do
          let(:params) { { stage: "WD" } }

          it "has harmonized stage assigned" do
            expect(subject.stage.harmonized_code)
              .to eq(Identifier.build_harmonized_stage_code("20", "20"))
          end
        end

        context "when stage is a code" do
          let(:params) { { stage: "30.20" } }

          it "has harmonized stage assigned" do
            expect(subject.stage.harmonized_code)
              .to eq(Identifier.build_harmonized_stage_code("30", "20"))
          end

          it "renders identifier with associated stage" do
            expect(subject.to_s).to eq("ISO/CD #{number}")
          end

          context "when stage code don't have associated abbreviation" do
            let(:params) { { stage: "60.60" } }

            it "renders identifier without stage" do
              expect(subject.to_s).to eq("ISO #{number}")
            end
          end

          context "stage code 50.00" do
            let(:params) { { stage: "50.00" } }

            it "renders FDIS stage" do
              expect(subject.to_s).to eq("ISO/FDIS #{number}")
            end
          end
        end

        context "when have harmonized code and abbr" do
          context "at stage PRF" do
            let(:stage) { Identifier.build_stage(harmonized_code: "50.00", abbr: :PRF) }

            it "renders separate stage for PubID" do
              expect(subject.to_s(with_prf: true)).to eq("ISO/PRF #{number}")
            end

            it "renders separate numeric stage for URN" do
              expect(subject.urn).to eq("urn:iso:std:iso:#{number}:stage-50.00")
            end
          end

          context "at stage FDIS" do
            let(:stage) { "FDIS" }

            it "renders separate stage for PubID" do
              expect(subject.to_s).to eq("ISO/FDIS #{number}")
            end

            it "renders separate numeric stage for URN" do
              expect(subject.urn).to eq("urn:iso:std:iso:#{number}:stage-draft")
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

          it "returns TechnicalReport class" do
            expect(subject).to be_a(Identifier::TechnicalReport)
          end
        end

        context "when FDTR typed stage" do
          let(:stage) { "FDTR" }

          it "renders correct identifier" do
            expect(subject.to_s).to eq("ISO/FDTR #{number}")
          end

          it "returns TechnicalReport class" do
            expect(subject).to be_a(Identifier::TechnicalReport)
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
            expect { subject }.to raise_exception(Pubid::Core::Errors::StageInvalidError)
          end
        end
      end

      context "when IS type" do
        let(:params) { { type: :is } }

        it "do not include IS stage" do
          expect(subject.to_s).to eq("ISO #{number}")
        end

        it "do not include IS stage for URN" do
          expect(subject.urn).to eq("urn:iso:std:iso:#{number}")
        end

        it "should return IS class" do
          expect(subject).to be_a(Identifier::InternationalStandard)
        end

        it "returns typed_stage_name" do
          expect(subject.typed_stage_name).to eq("International Standard")
        end

        it "returns typed_stage_abbrev" do
          expect(subject.typed_stage_abbrev).to eq(nil)
        end
      end

      context "when have typed stage" do
        let(:params) { { stage: typed_stage } }
        let(:typed_stage) { "DTR" }

        it "renders correct identifier" do
          expect(subject.to_s).to eq("ISO/DTR #{number}")
        end

        it "has related harmonized stage codes assigned" do
          expect(subject.stage.harmonized_code.stages)
            .to eq(%w[40.00 40.20 40.60 40.92 40.93 40.98 40.99])
        end

        it "renders document with typed stage" do
          expect(subject.to_s).to eq("ISO/DTR 123")
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

        context "with another type but no stage" do
          let(:type) { :tr }

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

        context "when PRF stage" do
          let(:params) { { type: :dir, stage: "PRF" }}

          it "render DIR document" do
            expect(subject.to_s).to eq("ISO DIR #{number}")
          end

          it "returns typed_stage_name" do
            expect(subject.typed_stage_name).to eq("Proof of a new Directives")
          end

          it "returns typed_stage_abbrev" do
            expect(subject.typed_stage_abbrev).to eq("PRF DIR")
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
          described_class.create(
            type: :amd, number: 1, year: 2021, stage: :damd,
            base: described_class.create(number: number, year: 2019, language: "en"))
            .to_s(format: format)
        end
        let(:number) { 123 }

        context "when ref_num_short format" do
          let(:format) { :ref_num_short }

          it { expect(subject).to eq("ISO #{number}:2019/DAM 1:2021(E)") }
        end

        context "when ref_num_long format" do
          let(:format) { :ref_num_long }

          it { expect(subject.to_s).to eq("ISO #{number}:2019/DAM 1:2021(en)") }
        end

        context "when ref_dated format" do
          let(:format) { :ref_dated }

          it { expect(subject.to_s).to eq("ISO #{number}:2019/DAM 1:2021") }
        end

        context "when ref_dated_long format" do
          let(:format) { :ref_dated_long }

          it { expect(subject.to_s).to eq("ISO #{number}:2019/DAM 1:2021") }
        end

        context "when ref_undated format" do
          let(:format) { :ref_undated }

          it { expect(subject.to_s).to eq("ISO #{number}:2019/DAM 1") }
        end

        context "when ref_undated_long" do
          let(:format) { :ref_undated_long }

          it { expect(subject.to_s).to eq("ISO #{number}:2019/DAM 1") }
        end
      end
    end
  end
end
