module Pubid::Nist
  RSpec.describe Series do
    let(:short_series) { "SP" }
    let(:long_series) { "Special Publication" }

    it "returns long title for serie" do
      expect(described_class.new(series: short_series).to_s(:long))
        .to eq(long_series)
    end

    context "when using new NIST IR serie" do
      let(:short_series) { "IR" }
      let(:series) { "IR" }

      it "returns the same short code" do
        expect(described_class.new(series: series).to_s(:short)).to eq(short_series)
      end
    end

    context "when wrong serie" do
      subject { described_class.new(series: series) }
      let(:series) { "WRONG-SERIE" }

      it { expect { subject }.to raise_error(Errors::SerieInvalidError) }
    end
  end
end
