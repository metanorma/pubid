module Pubid::Iso
  RSpec.describe TypedStage do
    subject { described_class.new(type: type, stage: stage, abbr: abbr) }
    let(:abbr) { nil }
    let(:type) { nil }
    let(:stage) { nil }

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

      it "returns stage 40.00" do
        expect(subject.stage).to eq(Stage.new(harmonized_code: "40.00"))
      end
    end

    context "when using TR type and stage 40.00" do
      let(:type) { :tr }
      let(:stage) { Stage.new(harmonized_code: "40.00") }

      it "returns correct abbreviation" do
        expect(subject.to_s).to eq("DTR")
      end
    end
  end
end
