RSpec.describe Pubid::Iso::Supplement do
  describe "#==" do
    subject do
      first_supplement == second_supplement
    end

    let(:first_supplement) do
      Pubid::Iso::Supplement.new(version: 1, number: first_supplement_year, stage: first_supplement_stage)
    end
    let(:second_supplement) do
      Pubid::Iso::Supplement.new(version: 1, number: second_supplement_year, stage: second_supplement_stage)
    end
    let(:first_supplement_year) { nil }
    let(:second_supplement_year) { nil }
    let(:first_supplement_stage) { nil }
    let(:second_supplement_stage) { nil }

    context "when have equal supplement version and year" do
      let(:first_supplement_year) { 2000 }
      let(:second_supplement_year) { 2000 }

      it { is_expected.to be_truthy }
    end

    context "when query don't have a year" do
      let(:second_supplement_year) { 2000 }

      it { is_expected.to be_truthy }
    end

    context "when years is different" do
      let(:first_supplement_year) { 2001 }
      let(:second_supplement_year) { 2000 }

      it { is_expected.to be_falsey }
    end

    context "when query without stage but stage in results" do
      let(:second_supplement_stage) { "CD" }

      it { is_expected.to be_truthy }
    end

    context "when query with stage" do
      let(:first_supplement_stage) { "CD" }

      context "different stage in results" do
        let(:second_supplement_stage) { "PWI" }

        it { is_expected.to be_falsey }
      end

      context "no stage in results" do
        it { is_expected.to be_falsey }
      end
    end
  end

  describe "rendering" do
    subject do
      Pubid::Iso::Supplement.new(version: 1, number: supplement_year, stage: supplement_stage)
    end

    context "when supplement has stage" do
      let(:supplement_year) { 2000 }
      let(:supplement_stage) { "CD" }

      let(:pubid_number) { "1:2000" }
      let(:urn_stage) { ":stage-30.00" }
      let(:urn_number) { ":2000:v1" }

      it { expect(subject.render_pubid_stage).to eq(supplement_stage) }
      it { expect(subject.render_pubid_number).to eq(pubid_number) }

      it { expect(subject.render_urn_stage).to eq(urn_stage) }
      it { expect(subject.render_urn_number).to eq(urn_number) }
    end
  end
end
