module Pubid::Core
  RSpec.describe Stage do
    context "when abbreviation" do
      subject { described_class.new(abbr: abbrev) }
      let(:abbrev) { :WD }

      it "returns correct harmonized stage code" do
        expect(subject.harmonized_code).to eq(Pubid::Core::HarmonizedStageCode.new(Stage::STAGES[abbrev.to_s]))
      end

      context "wrong code" do
        let(:abbrev) { :ABC }

        it "raise an error" do
          expect { subject }.to raise_exception(Pubid::Core::Errors::StageInvalidError)
        end
      end
    end

    context "when harmonized stage code" do
      subject { described_class.new(harmonized_code: harmonized_code) }
      let(:harmonized_code) { harmonized_code_object }
      let(:harmonized_code_object) { Pubid::Core::HarmonizedStageCode.new(Stage::STAGES["WD"]) }

      it "returns abbreviated code" do
        expect(subject.abbr).to eq("WD")
      end

      context "when harmonized_code is a string" do
        let(:harmonized_code) { "50.00" }

        it "assigns correct harmonized stage code" do
          expect(subject.harmonized_code.stages).to eq([harmonized_code])
        end

        context "when harmonized_code has only stage" do
          let(:harmonized_code) { "50" }

          it "assigns correct harmonized stage code" do
            expect(subject.harmonized_code.stages).to eq(["#{harmonized_code}.00"])
          end
        end

        context "when harmonized_code 60.00" do
          let(:harmonized_code) { "60.00" }

          it "returns abbreviated code" do
            expect(subject.abbr).to eq(nil)
          end
        end

        context "when harmonized_code 20.60" do
          let(:harmonized_code) { "20.60" }

          it "returns abbreviated code" do
            expect(subject.abbr).to eq("WD")
          end
        end

        context "when harmonized_code 10.99" do
          let(:harmonized_code) { "10.99" }

          it "returns abbreviated code" do
            expect(subject.abbr).to eq("AWI")
          end
        end

        context "when harmonized_code 20.00" do
          let(:harmonized_code) { "20.00" }

          it "returns abbreviated code" do
            expect(subject.abbr).to eq("AWI")
          end
        end

        context "when harmonized_code 50.20" do
          let(:harmonized_code) { "50.20" }

          it "returns abbreviated code" do
            expect(subject.abbr).to eq("PRF")
          end
        end

        context "when harmonized_code 60.60" do
          let(:harmonized_code) { "60.60" }

          it "returns abbreviated code" do
            expect(subject.abbr).to eq(nil)
          end
        end
      end
    end

    context "when harmonized code and abbreviation" do
      subject { described_class.new(harmonized_code: harmonized_code, abbr: abbrev) }
      let(:harmonized_code) { Pubid::Core::HarmonizedStageCode.new("20", "00") }
      let(:abbrev) { :CD }

      it "returns abbreviated code" do
        expect(subject.abbr).to eq(abbrev.to_s)
      end

      it "returns harmonized code" do
        expect(subject.harmonized_code).to eq(harmonized_code)
      end
    end

    describe "#==" do
      subject do
        first_stage == second_stage
      end

      context "when have the same harmonized_code" do
        let(:first_stage) do
          described_class.new(harmonized_code: "50.00")
        end
        let(:second_stage) do
          described_class.new(harmonized_code: "50.00")
        end

        it { is_expected.to be_truthy }
      end

      context "when have the different harmonized_code" do
        let(:first_stage) do
          described_class.new(harmonized_code: "50.00")
        end
        let(:second_stage) do
          described_class.new(harmonized_code: "20.00")
        end

        it { is_expected.to be_falsey }
      end
    end

    describe "#name" do
      subject { described_class.new(abbr: abbrev).name }

      context "when stage CD" do
        let(:abbrev) { :CD }

        it { is_expected.to eq("Committee Draft") }
      end
    end

    describe "#has_stage?" do
      subject { described_class.has_stage?(stage) }

      context "when existing stage" do
        let(:stage) { "CD" }

        it { is_expected.to be_truthy }
      end

      context "when not existing stage" do
        let(:stage) { "ABC" }

        it { is_expected.to be_falsey }
      end
    end

    describe "#empty_abbr?" do
      subject { described_class.new(abbr: abbrev).empty_abbr?(with_prf: with_prf) }
      let(:with_prf) { false }

      context "when abbr is nil" do
        let(:abbrev) { nil }

        it { is_expected.to be_truthy }
      end

      context "when PRF stage" do
        let(:abbrev) { :PRF }

        it { is_expected.to be_truthy }

        context "with option with_prf == true" do
          let(:with_prf) { true }

          it { is_expected.to be_falsey }
        end
      end

      context "when CD stage" do
        let(:abbrev) { :CD }

        it { is_expected.to be_falsey }
      end
    end

    describe "#to_s" do
      subject { described_class.new(abbr: abbrev).to_s(opts) }
      let(:opts) { {} }

      context "when CD" do
        let(:abbrev) { :CD }

        it { is_expected.to eq("CD") }
      end

      context "when PRF" do
        let(:abbrev) { :PRF }

        it { is_expected.to be_empty }

        context "when option with_prf true" do
          let(:opts) { { with_prf: true } }

          it { is_expected.to eq("PRF") }
        end
      end
    end
  end
end
