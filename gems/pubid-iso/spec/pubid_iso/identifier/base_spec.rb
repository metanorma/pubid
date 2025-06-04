module Pubid::Iso
  module Identifier
    RSpec.describe Base do
      describe "#transform_supplements" do
        subject { described_class.transform_supplements(supplements, base_params) }
        let(:base_params) do
          { publisher: "ISO",
            number: "1",
            year: "2016",
          }
        end
        let(:supplements) do
          [{ type: "Amd", number: "2", iteration: "3" }]
        end

        it "returns supplement as main identifier" do
          expect(subject.number).to eq("2")
          expect(subject.type[:key]).to eq(:amd)
        end

        it "assigns base identifier to supplement" do
          expect(subject.base).to eq(Identifier.create(number: "1", year: 2016))
        end

        context "when have amendment and corrigendum" do
          let(:supplements) do
            [{ type: "Amd", number: "1" },
             { type: "Cor", number: "2", iteration: "3" }]
          end

          it "returns corrigendum as main identifier" do
            expect(subject.type[:key]).to eq(:cor)
          end

          it "assigns amendment as base for corrigendum" do
            expect(subject.base.type[:key]).to eq(:amd)
          end
        end
      end
    end
  end
end
