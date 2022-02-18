RSpec.describe NistPubid::Serie do
  let(:short_serie) { "NIST SP" }
  let(:long_serie) { "Special Publication" }

  it "returns long title for serie" do
    expect(described_class.new(serie: short_serie).to_s(:long))
      .to eq(long_serie)
  end

  context "when using new NIST IR serie" do
    let(:short_serie) { "NIST IR" }
    let(:serie) { "NIST IR" }

    it "returns the same short code" do
      expect(described_class.new(serie: serie).to_s(:short)).to eq(short_serie)
    end
  end
end
