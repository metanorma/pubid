module Pubid::Iso
  RSpec.describe Renderer::Base do
    subject { described_class.new(params) }

    describe "#prerender" do
      context "attribute type_stage" do
        subject { described_class.new(params).prerender(pdf_format: pdf_format).prerendered_params[:type_stage] }
        let(:params) { { stage: stage, type: type, copublisher: copublisher } }
        let(:copublisher) { nil }
        let(:type) { nil }
        let(:stage) { nil }
        let(:pdf_format) { false }

        context "when type and stage" do
          let(:stage) { Stage.new(abbr: :WD) }
          let(:type) { "TR" }

          context "when no copublisher" do
            it { is_expected.to eq("/WD TR") }

            context "when pdf format" do
              let(:pdf_format) { true }
              it { is_expected.to eq("WD TR") }
            end
          end

          context "when have copublisher" do
            let(:copublisher) { "IEC" }

            it { is_expected.to eq(" TR WD") }

            context "when pdf format" do
              let(:pdf_format) { true }
              it { is_expected.to eq("WD TR") }
            end
          end
        end

        context "when only type" do
          let(:type) { "TR" }

          it { is_expected.to eq("/TR") }

          context "when have copublisher" do
            let(:copublisher) { "IEC" }

            it { is_expected.to eq(" TR") }

            context "when pdf format" do
              let(:pdf_format) { true }
              it { is_expected.to eq("TR") }
            end
          end

          context "when pdf format" do
            let(:pdf_format) { true }
            it { is_expected.to eq("TR") }
          end
        end

        context "when only stage" do
          let(:stage) { Stage.new(abbr: :WD) }

          it { is_expected.to eq("/WD") }

          context "when pdf format" do
            let(:pdf_format) { true }
            it { is_expected.to eq("WD") }
          end

          context "when have copublisher" do
            let(:copublisher) { "IEC" }

            it { is_expected.to eq(" WD") }

            context "when pdf format" do
              let(:pdf_format) { true }
              it { is_expected.to eq("WD") }
            end
          end
        end

        context "when DIS stage" do
          let(:stage) { Stage.new(abbr: :DIS) }

          context "when type and stage" do
            let(:type) { "TR" }

            it { is_expected.to eq("/DTR") }

            context "when pdf format" do
              let(:pdf_format) { true }
              it { is_expected.to eq("DTR") }
            end

            context "when have copublisher" do
              let(:copublisher) { "IEC" }

              it { is_expected.to eq(" DTR") }

              context "when pdf format" do
                let(:pdf_format) { true }
                it { is_expected.to eq("DTR") }
              end
            end
          end

          context "when only stage" do
            context "when have copublisher" do
              let(:copublisher) { "IEC" }

              it { is_expected.to eq(" DIS") }

              context "when pdf format" do
                let(:pdf_format) { true }
                it { is_expected.to eq("DIS") }
              end
            end
          end
        end
      end
    end
  end
end
