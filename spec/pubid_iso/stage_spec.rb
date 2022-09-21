RSpec.describe Pubid::Iso::Stage do
  context "when abbreviation" do
    subject { described_class.new(abbr: abbrev) }
    let(:abbrev) { :FDIS }

    it "returns correct harmonized stage code" do
      expect(subject.harmonized_code).to eq(Pubid::Iso::HarmonizedStageCode.new("50", "00"))
    end

    context "wrong code" do
      let(:abbrev) { :ABC }

      it "raise an error" do
        expect { subject }.to raise_exception(Pubid::Iso::Errors::StageInvalidError)
      end
    end
  end

  context "when harmonized stage code" do
    subject { described_class.new(harmonized_code: harmonized_code) }
    let(:harmonized_code) { harmonized_code_object }
    let(:harmonized_code_object) { Pubid::Iso::HarmonizedStageCode.new("50", "00") }

    it "returns abbreviated code" do
      expect(subject.abbr).to eq(:FDIS)
    end

    context "when harmonized_code is a string" do
      let(:harmonized_code) { "50.00" }

      it "assigns correct harmonized stage code" do
        expect(subject.harmonized_code).to eq(harmonized_code_object)
      end

      context "when harmonized_code has only stage" do
        let(:harmonized_code) { "50" }

        it "assigns correct harmonized stage code" do
          expect(subject.harmonized_code).to eq(harmonized_code_object)
        end
      end

      context "when harmonized_code 50.20" do
        let(:harmonized_code) { "50.20" }

        it "returns abbreviated code" do
          expect(subject.abbr).to eq(:FDIS)
        end
      end
    end

    context "when harmonized_code is an integer" do
      let(:harmonized_code) { 50 }

      it "assigns correct harmonized stage code" do
        expect(subject.harmonized_code).to eq(harmonized_code_object)
      end
    end

  end

  context "when harmonized code and abbreviation" do
    subject { described_class.new(harmonized_code: harmonized_code, abbr: abbrev) }
    let(:harmonized_code) { Pubid::Iso::HarmonizedStageCode.new("50", "00") }
    let(:abbrev) { :FDIS }

    it "returns abbreviated code" do
      expect(subject.abbr).to eq(abbrev)
    end

    it "returns harmonized code" do
      expect(subject.harmonized_code).to eq(harmonized_code)
    end
  end
end
