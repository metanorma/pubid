RSpec.describe NistPubid::DocumentTransform do
  describe "transform parsed document into document class" do

    it "parses document" do
      expect(described_class.new.apply(NistPubid::DocumentParser.new.parse("NBS FIPS 100")))
        .to eq(NistPubid::Document.new(serie: NistPubid::Serie.new(serie: "NBS FIPS"),
                                       docnumber: "100",
                                       publisher: NistPubid::Publisher.new(publisher: "NBS")))
    end

    it "parses NIST SP 800-57pt1r4" do
      expect(described_class.new.apply(NistPubid::DocumentParser.new.parse("NIST SP 800-57pt1r4")))
        .to eq(NistPubid::Document.new(serie: NistPubid::Serie.new(serie: "NIST SP"),
                                       docnumber: "800-57",
                                       revision: "4",
                                       part: "1",
                                       publisher: NistPubid::Publisher.new(publisher: "NIST")))
    end
  end
end
