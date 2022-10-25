RSpec.describe Pubid::Iso::Supplement do
  describe "rendering" do
    context "when supplement has stage" do
      subject do
        Pubid::Iso::Supplement.new(number: 1, year: supplement_year, stage: supplement_stage)
      end

      let(:supplement_year) { 2000 }
      let(:supplement_stage) { Pubid::Iso::TypedStage.new(stage: :CD) }

      let(:pubid_number) { "1:2000" }
      let(:urn_stage) { ":stage-30.00" }
      let(:urn_number) { ":2000:v1" }

      it { expect(subject.render_pubid_stage).to eq("CD") }

      it { expect(subject.render_urn_stage).to eq(urn_stage) }
    end

    context "when supplement has iteration" do
      subject do
        Pubid::Iso::Supplement.new(number: 1, stage: Pubid::Iso::Stage.new(abbr: :CD), iteration: 1)
      end

      it { expect(subject.render_pubid_number).to eq("1.1") }

      context "when published document has iteration" do
        subject do
          Pubid::Iso::Supplement.new(number: 1, iteration: 1)
        end

        it { expect { subject }.to raise_error(an_instance_of(Pubid::Iso::Errors::PublishedIterationError)) }
      end
    end
  end

  describe "#==" do
    subject do
      first_supplement == second_supplement
    end

    let(:first_supplement) do
      described_class.new(number: 1, year: first_supplement_year, stage: first_supplement_stage)
    end
    let(:second_supplement) do
      described_class.new(number: 1, year: second_supplement_year, stage: second_supplement_stage)
    end
    let(:first_supplement_year) { nil }
    let(:second_supplement_year) { nil }
    let(:first_supplement_stage) { nil }
    let(:second_supplement_stage) { nil }

    context "when query without stage but stage in results" do
      let(:second_supplement_stage) { Pubid::Iso::Stage.new(abbr: :CD) }

      it { is_expected.to be_truthy }
    end

    context "when query with stage" do
      let(:first_supplement_stage) { Pubid::Iso::Stage.new(abbr: :CD) }

      context "different stage" do
        let(:second_supplement_stage) { Pubid::Iso::Stage.new(abbr: :PWI) }

        it { is_expected.to be_falsey }
      end

      context "when the second stage is nil" do
        it { is_expected.to be_falsey }
      end

      context "the same stage" do
        let(:second_supplement_stage) { Pubid::Iso::Stage.new(abbr: :CD) }

        it { is_expected.to be_truthy }
      end
    end

  end
end
