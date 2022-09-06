RSpec.describe Pubid::Iso::HarmonizedStageCode do
  subject { described_class.new(stage_or_abbrev, substage) }
  let(:stage_or_abbrev) { nil }
  let(:substage) { nil }

  context "when symbol code" do
    let(:stage_or_abbrev) { :approval }
    let(:substage) { :registration }

    it "converts to abbreviation" do
      expect(subject.abbrev).to eq(:FDIS)
    end

    it "converts to digit code" do
      expect(subject.to_s).to eq("50.00")
    end
  end

  context "when digit code" do
    let(:stage_or_abbrev) { "50" }
    let(:substage) { "00" }

    it "converts to abbreviation" do
      expect(subject.abbrev).to eq(:FDIS)
    end

    context "wrong code" do
      let(:stage_or_abbrev) { "90" }
      let(:substage) { "00" }
    end
  end

  context "when abbreviation" do
    let(:stage_or_abbrev) { "FDIS" }

    it "converts to digit code" do
      expect(subject.to_s).to eq("50.00")
    end

    it "returns description" do
      expect(subject.description).to eq("Final text received or FDIS registered for formal approval")
    end

    context "wrong code" do
      it "raise an error"
    end
  end
end
