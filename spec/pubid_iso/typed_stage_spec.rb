module Pubid::Iso
  RSpec.describe TypedStage do
    subject { described_class.new(type: type, stage: stage, abbr: abbr) }
    let(:abbr) { nil }
    let(:type) { nil }
    let(:stage) { nil }

    describe "#has_typed_stage?" do
      subject { described_class.has_typed_stage?(typed_stage) }

      context "when existing typed stage" do
        let(:typed_stage) { "DTR" }

        it { is_expected.to be_truthy }
      end

      context "when not existing typed stage" do
        let(:typed_stage) { "ABC" }

        it { is_expected.to be_falsey }
      end
    end

    describe "#lookup_typed_stage" do
      subject do
        described_class.new(
          type: Type.new(:amd),
          stage: Stage.new(harmonized_code: HarmonizedStageCode.new("40.60"))
        ).lookup_typed_stage
      end

      it "returns correct typed stage" do
        expect(subject).to eq(:damd)
      end
    end

    describe "#parse" do
      subject { described_class.parse(stage_or_typed_stage) }

      context "when stage provided" do
        let(:stage_or_typed_stage) { "CD" }

        it "assigns according stage" do
          expect(subject.stage).to eq(Stage.new(abbr: :CD))
        end
      end

      context "when typed stage provided" do
        let(:stage_or_typed_stage) { "DTR" }

        it "assigns according typed stage and harmonized stage" do
          expect(subject.typed_stage).to eq(:dtr)
          expect(subject.stage.harmonized_code)
            .to eq(HarmonizedStageCode.new(%w[40.00 40.20 40.60 40.92 40.93 50.00 50.20 50.60 50.92]))
        end

        # it "don't assign stage" do
        #   expect(subject.stage).to be_nil
        # end
      end

      context "when type provided" do
        let(:stage_or_typed_stage) { "TR" }

        it "assigns according type" do
          expect(subject.type).to eq(Type.new(:tr))
        end
      end
    end

    context "when CD TR" do
      let(:type) { :tr }
      let(:stage) { :CD }

      it "returns correct abbreviation" do
        expect(subject.to_s).to eq("CD TR")
      end

      it "returns type" do
        expect(subject.type).to eq(:tr)
      end

      it "returns stage" do
        expect(subject.stage.abbr).to eq("CD")
      end
    end

    context "when DTR" do
      let(:abbr) { :dtr }

      it "returns correct abbreviation" do
        expect(subject.to_s).to eq("DTR")
      end

      it "returns type" do
        expect(subject.type).to eq(:tr)
      end

      it "returns stage codes related to DTR" do
        expect(subject.stage).to eq(Stage.new(
          harmonized_code: HarmonizedStageCode.new(
            %w[40.00 40.20 40.60 40.92 40.93 50.00 50.20 50.60 50.92]
          )
        ))
      end
    end

    context "when using TR type and stage 40.00" do
      let(:type) { :tr }
      let(:stage) { Stage.new(harmonized_code: "40.00") }

      it "returns correct abbreviation" do
        expect(subject.to_s).to eq("DTR")
      end
    end

    context "when using IS type" do
      let(:type) { :is }

      it "returns nothing" do
        expect(subject.to_s).to eq("")
      end

      context "with stage" do
        let(:stage) { :CD }

        it "returns only stage" do
          expect(subject.to_s).to eq("CD")
        end
      end
    end
  end
end
