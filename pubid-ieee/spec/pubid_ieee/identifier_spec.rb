module Pubid::Ieee
  RSpec.describe Identifier do
    describe "#convert_parser_parameters" do
      subject { described_class.convert_parser_parameters(**params) }

      let(:params) do
        { number: 1,
          parameters: { year: 1999 },
          organizations: { publisher: "IEEE" },
          type_status: { type: "Std" }
        }
      end

      let(:result) do
        { number: 1, year: 1999, publisher: "IEEE", type: "Std" }
      end

      it { expect(subject).to eq(result) }
    end
  end
end
