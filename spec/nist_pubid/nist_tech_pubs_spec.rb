RSpec.describe NistPubid::NistTechPubs, vcr: true do
  describe "#fetch" do
    it "fetch doc identifiers from nist_tech_pubs" do
      expect(described_class.fetch.map { |d| d[:id] })
        .to include("NBS BH 1",
                    "NIST SP 1800-15",
                    "NIST SP 1265",
                    "NBS FIPS 83",
                    "NISTIR 8379")
    end

    it "fetches doi identifiers" do
      expect(described_class.fetch.map { |d| d[:doi] })
        .to include("NBS.BH.1",
                    "NIST.SP.1800-15",
                    "NIST.SP.1265",
                    "NBS.FIPS.83",
                    "NIST.IR.8379")
    end
  end

  describe "#convert" do
    it "converts old pubid to new NIST PubID" do
      expect(described_class.convert({ id: "NISTIR 8379" }))
        .to eq("NIST IR 8379")
    end

    it "keeps correct NIST PubID the same" do
      expect(described_class.convert({ id: "NIST SP 800-133r2" }))
        .to eq("NIST SP 800-133r2")
      expect(described_class.convert({ id: "NIST SP 800-160v1" }))
        .to eq("NIST SP 800-160v1")
    end

    it "uses doi when cannot parse document id" do
      expect(described_class.convert(
               { id: "NBS CIRC re3", doi: "NBS.CIRC.5e3" },
             )).to eq("NBS CIRC 5e3")
    end

    it "uses doi when doi more complete then id" do
      expect(described_class.convert(
               { id: "NIST SP 260-162", doi: "NIST SP 260-162 2006ed." },
             )).to eq("NIST SP 260-162e2006")
    end
  end

  describe "#comply_with_pubid" do
    it "returns identifier comply with NIST PubID" do
      expect(described_class.comply_with_pubid.map { |d| d[:id] })
        .to include("NIST SP 800-133r2")
    end
  end

  describe "#different_with_pubid" do
    it "returns identifiers not comply with NIST PubID" do
      expect(described_class.different_with_pubid.map { |d| d[:id] })
        .to include("NISTIR 8379")
    end
  end

  describe "#parse_fail_with_pubid" do
    it "returns identifiers fail to parse" do
      expect(described_class.parse_fail_with_pubid.map { |d| d[:id] })
        .to include("NBS CIRC e2")
    end
  end
end
