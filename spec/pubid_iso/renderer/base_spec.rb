module Pubid::Iso
  RSpec.describe Renderer::Base do
    subject { described_class.new(params) }

    describe "#prerender" do
      context "attribute type_stage" do
        subject { described_class.new(params).prerender.prerendered_params[:type_stage] }
        let(:params) { { stage: stage, type: type, copublisher: copublisher } }
        let(:copublisher) { nil }
        let(:type) { nil }
        let(:stage) { nil }
        let(:pdf_format) { false }

        context "when type and stage" do
          let(:stage) { Stage.new(abbr: :WD) }
          let(:type) { Type.new(:tr) }

          context "when no copublisher" do
            it { is_expected.to eq("WD TR") }
          end

          context "when have copublisher" do
            let(:copublisher) { "IEC" }

            it { is_expected.to eq("WD TR") }
          end
        end

        context "when only type" do
          let(:type) { "TR" }

          it { is_expected.to eq("TR") }

          context "when have copublisher" do
            let(:copublisher) { "IEC" }

            it { is_expected.to eq("TR") }
          end
        end

        context "when only stage" do
          let(:stage) { Stage.new(abbr: :WD) }

          it { is_expected.to eq("WD") }

          context "when have copublisher" do
            let(:copublisher) { "IEC" }

            it { is_expected.to eq("WD") }
          end
        end

        context "when DIS stage" do
          let(:stage) { Stage.new(abbr: :DIS) }

          context "when type and stage" do
            let(:type) { "TR" }

            it { is_expected.to eq("DTR") }

            context "when have copublisher" do
              let(:copublisher) { "IEC" }

              it { is_expected.to eq("DTR") }

            end
          end

          context "when only stage" do
            context "when have copublisher" do
              let(:copublisher) { "IEC" }

              it { is_expected.to eq("DIS") }
            end
          end
        end
      end
    end
  end
end
