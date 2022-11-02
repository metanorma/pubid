module Pubid::Iso
  RSpec.describe HarmonizedStageCode do
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
              Errors::HarmonizedStageCodeInvalidError)
          end
        end
      end
    end

    context "when stage is a string" do
      let(:stage) { "20.20" }

      it "resolves it as stage and substage" do
        expect(subject.to_s).to eq("20.20")
      end

      it "returns stage and substage separately" do
        expect(subject.stage).to eq("20")
        expect(subject.substage).to eq("20")
      end
    end

    context "when have fuzzy stages" do
      let(:stage) { %w[20.00 20.20 20.60] }

      it "returns true when compare with stage included in fuzzy stage" do
        expect(subject == HarmonizedStageCode.new("20.20")).to be_truthy
      end

      it "returns true for #fuzzy?" do
        expect(subject.fuzzy?).to be_truthy
      end

      context "when only one stage" do
        let(:stage) { "20.20" }

        it "returns false for #fuzzy?" do
          expect(subject.fuzzy?).to be_falsey
        end
      end

      context "fuzzy stages in the range from 00 to 50" do
        let(:stage) { %w[20.00 20.20 20.60] }

        it "returns draft instead of numbers" do
          expect(subject.to_s).to eq("draft")
        end

        context "when include cancelled stages" do
          let(:stage) { %w[20.00 20.20 20.60 20.98] }

          it "raises an error when try to convert to single stage code" do
            expect { subject.to_s }.to raise_exception(Errors::HarmonizedStageRenderingError)
          end
        end
      end

      context "several canceled stages" do
        let(:stage) { %w[00.98 10.98 20.98] }

        it "returns canceled instead of numbers" do
          expect(subject.to_s).to eq("canceled")
        end
      end

      context "several published stages" do
        let(:stage) { %w[60.00 60.60] }

        it "returns canceled instead of numbers" do
          expect(subject.to_s).to eq("published")
        end
      end
    end
  end
end
