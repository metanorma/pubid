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
        expect { subject }.to raise_exception(Pubid::Iso::Errors::CodeNotValidError)
      end
    end
  end

  context "when harmonized stage code" do
    subject { described_class.new(harmonized_code: harmonized_code) }
    let(:harmonized_code) { Pubid::Iso::HarmonizedStageCode.new("50", "00") }

    it "returns abbreviated code" do
      expect(subject.abbr).to eq(:FDIS)
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
