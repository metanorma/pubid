module Pubid::Nist
  RSpec.describe Update do
    subject { described_class.new(**params) }

    context "when only month provided" do
      let(:params) { { month: 12, "year": 1999 } }

      it "returns number 1" do
        expect(subject.number).to eq(1)
      end
    end

    context "when year only 2 digits" do
      let(:params) { { year: 90 } }

      it "returns full year" do
        expect(subject.year).to eq("1990")
      end
    end

    context "when month is a word" do
      let(:params) { { year: 1990, month: "Jun" } }

      it "returns month as number" do
        expect(subject.month).to eq(6)
      end
    end
  end
end
