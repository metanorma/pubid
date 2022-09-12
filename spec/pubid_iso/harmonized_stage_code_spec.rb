RSpec.describe Pubid::Iso::HarmonizedStageCode do
  subject { described_class.new(stage, substage) }
  let(:stage) { nil }
  let(:substage) { nil }

  context "when symbol code" do
    let(:stage) { :approval }
    let(:substage) { :registration }

    it "converts to digit code" do
      expect(subject.to_s).to eq("50.00")
    end
  end

  context "when digit code" do
    let(:stage) { "50" }
    let(:substage) { "00" }

    context "wrong code" do
      let(:stage) { "90" }
      let(:substage) { "00" }

      it "raise an error" do
        expect { subject }.to raise_exception(Pubid::Iso::Errors::HarmonizedStageCodeInvalidError)
      end
    end
  end
end
