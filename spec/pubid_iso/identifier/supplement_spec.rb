module Pubid::Iso
  module Identifier
    RSpec.describe Supplement do
      context "when create supplement identifier" do
        let(:base) { Identifier.create(**{ number: number }.merge(params)) }

        subject { described_class.new(number: 1, base: base, **supplement_params) }
        let(:params) { { year: year } }
        let(:number) { 123 }

        let(:supplement_params) { {} }
        let(:year) { 1999 }
        let(:stage) { nil }

        it "renders supplement with base document" do
          expect(subject.to_s).to eq("ISO 123:1999/Suppl 1")
        end

        context "supplement with year" do
          let(:supplement_params) { { year: 2000 } }

          it "renders supplement with base document and year" do
            expect(subject.to_s).to eq("ISO 123:1999/Suppl 1:2000")
          end
        end

        context "supplement without number but year" do
          subject { described_class.new(base: base, **supplement_params) }
          let(:supplement_params) { { year: 2000 } }

          it "renders supplement with base document and year" do
            expect(subject.to_s).to eq("ISO 123:1999/Suppl:2000")
          end
        end

        context "supplement with iteration" do
          let(:result) { "ISO 123:1999/Suppl 1.2" }
          let(:supplement_params) { { iteration: 2 } }

          it "renders supplement with iteration" do
            expect(subject.to_s).to eq(result)
          end
        end

        context "draft supplement" do
          let(:result) { "ISO 123:1999/DSuppl 1" }
          let(:supplement_params) { { stage: "DSuppl" } }

          it "renders draft supplement" do
            expect(subject.to_s).to eq(result)
          end
        end

        context "NP Suppl" do
          let(:result) { "ISO 123:1999/NP Suppl 1" }
          let(:supplement_params) { { stage: "NP" } }

          it "renders supplement with NP stage" do
            expect(subject.to_s).to eq(result)
          end
        end

        context "AWI Suppl"
      end
    end
  end
end
