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
      let(:wrong_codes) do
        %w[00.92 00.93 10.93 20.92 20.93 30.93 50.93 60.20 60.92 60.93 60.98
           60.99 90.00 90.98 95.00 95.93 95.98]
      end

      it "raise an error" do
        wrong_codes.each do |code|
          expect { described_class.new(*code.split(".")) }.to raise_exception(
            Pubid::Iso::Errors::HarmonizedStageCodeInvalidError)
        end
      end
    end
  end
end
