RSpec.describe NistPubid::Publisher do
  let(:short_publisher) { "NIST" }
  let(:long_publisher) { "National Institute of Standards and Technology" }

  it "returns long title for publisher" do
    expect(described_class.new(publisher: short_publisher).to_s(:long))
      .to eq(long_publisher)
  end

  describe "#parse" do
    it "parses short code" do
      expect(described_class.parse("NIST SP 800-85Ar4").to_s(:long))
        .to eq("National Institute of Standards and Technology")
    end

    it "parses long code" do
      expect(described_class.parse(
        "National Institute of Standards and Technology SP 800-85Ar4")
          .to_s(:short))
        .to eq("NIST")
      expect(described_class.parse(
        "National Bureau of Standards SP 800-85Ar4")
                            .to_s(:short))
        .to eq("NBS")
    end

    it "returns NIST publisher when cannot parse the code" do
      expect(described_class.parse("SP 800-85Ar4").to_s(:short))
        .to eq("NIST")
    end
  end
end
