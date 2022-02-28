RSpec.describe PubidIso::Scrapper do
  subject { described_class.parse_page("/sites/isoorg/contents/data/standard/00/35/3569") }

  it "returns URN" do
    VCR.use_cassette "iso_4" do
      expect(subject).to include(urn: "urn:iso:std:iso:4:stage-90.93:ed-3:en,fr")
    end
  end
end
