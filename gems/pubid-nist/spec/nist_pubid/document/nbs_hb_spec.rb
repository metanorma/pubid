RSpec.describe Pubid::Nist::Identifier::Base do
  subject { described_class.parse(original_pubid) }

  let(:mr_pubid) { short_pubid.gsub(" ", ".") }
  let(:original_pubid) { short_pubid }
  let(:long_pubid) { nil }
  let(:abbrev_pubid) { nil }

  context "NBS HB 44e2-1955" do
    let(:original_pubid) { "NBS HB 44e2-1955" }
    let(:short_pubid) { "NBS HB 44e2" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS HB 105-1-1990" do
    let(:original_pubid) { "NBS HB 105-1-1990" }
    let(:short_pubid) { "NBS HB 105-1e1990" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS HB 105-3r1979" do
    let(:original_pubid) { "NBS HB 105-3r1979" }
    let(:short_pubid) { "NBS HB 105-3r1979" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS HB 111r1977" do
    let(:original_pubid) { "NBS HB 111r1977" }
    let(:short_pubid) { "NBS HB 111r1977" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS HB 130-1979" do
    let(:original_pubid) { "NBS HB 130-1979" }
    let(:short_pubid) { "NBS HB 130e1979" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS HB 131" do
    let(:original_pubid) { "NBS HB 131" }
    let(:short_pubid) { "NBS HB 131" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS HB 28supp1957pt1" do
    let(:original_pubid) { "NBS HB 28supp1957pt1" }
    let(:short_pubid) { "NBS HB 28pt1sup1957" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS HB 44e4" do
    let(:original_pubid) { "NBS HB 44e4" }
    let(:short_pubid) { "NBS HB 44e4" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS HB 105-8" do
    let(:original_pubid) { "NBS HB 105-8" }
    let(:short_pubid) { "NBS HB 105-8" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST HB 44-1988" do
    let(:original_pubid) { "NBS HB 44-1988" }
    let(:short_pubid) { "NBS HB 44e1988" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS.HB.28p11969" do
    let(:original_pubid) { "NBS.HB.28p11969" }
    let(:short_pubid) { "NBS HB 28pt1e1969" }
    let(:mr_pubid) { "NBS.HB.28pt1e1969" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS.HB.105-1r1990" do
    let(:original_pubid) { "NBS.HB.105-1r1990" }
    let(:short_pubid) { "NIST HB 105-1r1990" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS HB 67suppFeb1965" do
    let(:original_pubid) { "NBS HB 67suppFeb1965" }
    let(:short_pubid) { "NBS HB 67e196502sup" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS HB 67suppJune1965" do
    let(:original_pubid) { "NBS HB 67suppJune1965" }
    let(:short_pubid) { "NBS HB 67e196506sup" }

    it_behaves_like "converts pubid to different formats"
  end
end
