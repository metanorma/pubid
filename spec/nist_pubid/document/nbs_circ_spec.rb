RSpec.describe NistPubid::Document do
  subject { described_class.parse(original_pubid) }

  let(:mr_pubid) { short_pubid.gsub(" ", ".") }
  let(:original_pubid) { short_pubid }
  let(:long_pubid) { nil }
  let(:abbrev_pubid) { nil }

  context "NBS CIRC 11e2-1915" do
    let(:original_pubid) { "NBS CIRC 11e2-1915" }
    let(:short_pubid) { "NBS CIRC 11-1915e2" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC 25sup-1924" do
    let(:original_pubid) { "NBS CIRC 25sup-1924" }
    let(:short_pubid) { "NBS CIRC 25sup" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC 101e2sup" do
    let(:short_pubid) { "NBS CIRC 101e2sup" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC 154suprev" do
    let(:original_pubid) { "NBS CIRC 154suprev" }
    let(:short_pubid) { "NBS CIRC 154r1sup" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC 488sec1" do
    let(:short_pubid) { "NBS CIRC 488sec1" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC 74errata" do
    let(:original_pubid) { "NBS CIRC 74errata" }
    let(:short_pubid) { "NBS CIRC 74err" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC 54index" do
    let(:original_pubid) { "NBS CIRC 54index" }
    let(:short_pubid) { "NBS CIRC 54indx" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC 54indx" do
    let(:short_pubid) { "NBS CIRC 54indx" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC 25insert" do
    let(:original_pubid) { "NBS CIRC 25insert" }
    let(:short_pubid) { "NBS CIRC 25ins"}
    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC 25ins" do
    let(:short_pubid) { "NBS CIRC 25ins"}

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC e2" do
    let(:original_pubid) { "NBS CIRC e2" }
    let(:short_pubid) { "NBS CIRC 2e2" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC sup" do
    let(:original_pubid) { "NBS CIRC sup" }
    let(:short_pubid) { "NBS CIRC 24e7sup" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC supJun1925-Jun1926" do
    let(:original_pubid) { "NBS CIRC supJun1925-Jun1926" }
    let(:short_pubid) { "NBS CIRC 24e7sup2" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC supJun1925-Jun1927" do
    let(:original_pubid) { "NBS CIRC supJun1925-Jun1927" }
    let(:short_pubid) { "NBS CIRC 24e7sup3" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC 13e2revJune1908" do
    let(:original_pubid) { "NBS CIRC 13e2revJune1908" }
    let(:short_pubid) { "NBS CIRC 13e2rJune1908" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC 24supJan1924" do
    let(:original_pubid) { "NBS CIRC 24supJan1924" }
    let(:short_pubid) { "NBS CIRC 24e192401sup" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC 15-April1909" do
    let(:original_pubid) { "NBS CIRC 15-April1909" }
    let(:short_pubid) { "NBS CIRC 15e190904" }


    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC 24supJuly1922" do
    let(:original_pubid) { "NBS CIRC 24supJuly1922" }
    let(:short_pubid) { "NBS CIRC 24e192207sup" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS CIRC 539v10" do
    let(:original_pubid) { "NBS CIRC 539v10" }
    let(:short_pubid) { "NBS CIRC 539v10" }

    it_behaves_like "converts pubid to different formats"
  end
end
