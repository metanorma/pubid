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

  describe "#parse" do
    it "parses short code" do
      expect(described_class.parse(short_serie).to_s(:long)).to eq(long_serie)
    end

    it "parses long code" do
      expect(described_class.parse(long_serie).to_s(:short)).to eq(short_serie)
    end

    context "when publisher NBS" do
      let(:short_serie) { "Monograph 175" }

      it "should return the code with publisher NBS" do
        expect(described_class.parse(short_serie, NistPubid::Publisher.new(publisher: "NBS")).to_s(:short)).to eq("NBS MN")
      end
    end
  end
end
