RSpec.describe NistPubid::NistTechPubs do
  describe "#fetch" do
    it "fetch and parse doc identifiers from nist_tech_pubs", vcr: true do
      expect(described_class.fetch)
        .to include("NBS BH 1",
                    "NIST SP 1800-15",
                    "NIST SP 1265",
                    "NBS FIPS 83",
                    "NISTIR 8379")
    end
  end
end
