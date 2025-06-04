module Pubid::Cen
  module Renderer
    RSpec.describe Base do
      describe "#sort_supplements" do
        subject { described_class.new({}).sort_supplements([first_supplement, second_supplement]) }
        let(:first_supplement) { Identifier::Amendment.new(year: 1999, number: 1) }
        let(:second_supplement) do
          Identifier::Amendment.new(year: second_supplement_year,
                                    number: second_supplement_number)
        end
        let(:second_supplement_number) { 1 }
        let(:second_supplement_year) { 1999 }

        context "when the same year" do
          let(:second_supplement_number) { 2 }

          it "returns earlier supplement first" do
            expect(subject).to eq([first_supplement, second_supplement])
          end
        end

        context "when different year, but same number" do
          let(:second_supplement_year) { 1998 }

          it "returns earlier supplement first" do
            expect(subject).to eq([second_supplement, first_supplement])
          end
        end

        context "when same year but one supplement without number" do
          let(:second_supplement_number) { nil }

          it "returns supplement without number first" do
            expect(subject).to eq([second_supplement, first_supplement])
          end
        end
      end
    end
  end
end
