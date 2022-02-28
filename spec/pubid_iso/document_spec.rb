RSpec.describe PubidIso::Document do
  subject { described_class.parse(original_pubid) }

  context "ISO 4" do
    let(:original_pubid) { "ISO 4" }
    let(:document_url) { "/sites/isoorg/contents/data/standard/06/83/68355" }

    it "returns correct document url" do
      VCR.use_cassette "iso_4_algolia" do
        expect(subject.url).to eq(document_url)
      end
    end
  end
end
