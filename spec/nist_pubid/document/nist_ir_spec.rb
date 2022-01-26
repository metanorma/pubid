RSpec.describe NistPubid::Document do
  subject { described_class.parse(original_pubid) }

  let(:mr_pubid) { short_pubid.gsub(" ", ".") }
  let(:original_pubid) { short_pubid }
  let(:long_pubid) { nil }
  let(:abbrev_pubid) { nil }

  context "NBS IR 73-197r" do
    let(:original_pubid) { "NBS IR 73-197r" }
    let(:short_pubid) { "NBS IR 73-197r1" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 4743rJun1992" do
    let(:original_pubid) { "NIST IR 4743rJun1992" }
    let(:short_pubid) { "NIST IR 4743rJun1992" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NISTIR 8115r1/upd" do
    let(:original_pubid) { "NISTIR 8115r1-upd" }
    let(:short_pubid) { "NIST IR 8115r1/Upd1-202103" }
    let(:mr_pubid) { "NIST.IR.8115r1.u1-202103" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NISTIR 8170-upd" do
    let(:original_pubid) { "NISTIR 8170-upd" }
    let(:short_pubid) { "NIST IR 8170/Upd1-202003" }
    let(:mr_pubid) { "NIST.IR.8170.u1-202003" }

    it_behaves_like "converts pubid to different formats"
  end

  context "when using old NISTIR serie code" do
    let(:original_pubid) { "NISTIR 8115" }
    let(:short_pubid) { "NIST IR 8115" }
    let(:long_pubid) do
      "National Institute of Standards and Technology Interagency or"\
          " Internal Report 8115"
    end
    let(:abbrev_pubid) do
      "Natl. Inst. Stand. Technol. Interagency or Internal Report"\
          " 8115"
    end

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 8115chi" do
    let(:original_pubid) { "NIST IR 8115chi" }
    let(:short_pubid) { "NIST IR 8115(zho)" }
    let(:mr_pubid) { "NIST.IR.8115.zho" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 8118r1es" do
    let(:original_pubid) { "NIST IR 8118r1es" }
    let(:short_pubid) { "NIST IR 8118r1(spa)" }
    let(:mr_pubid) { "NIST.IR.8118r1.spa" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST.IR.8115viet" do
    let(:original_pubid) { "NIST.IR.8115viet" }
    let(:short_pubid) { "NIST IR 8115(vie)" }
    let(:mr_pubid) { "NIST.IR.8115.vie" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST.IR.8178port" do
    let(:original_pubid) { "NIST.IR.8178port" }
    let(:short_pubid) { "NIST IR 8178(por)" }
    let(:mr_pubid) { "NIST.IR.8178.por" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 6529-a" do
    let(:original_pubid) { "NIST IR 6529-a" }
    let(:short_pubid) { "NIST IR 6529-A" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NBS.IR.73-212" do
    let(:original_pubid) { "NBS.IR.73-212" }
    let(:short_pubid) { "NBS IR 73-212" }
    let(:mr_pubid) { "NBS.IR.73-212" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 5672-2018" do
    let(:original_pubid) { "NIST IR 5672-2018" }
    let(:short_pubid) { "NIST IR 5672e2018" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 6969-2018" do
    let(:original_pubid) { "NIST IR 6969-2018" }
    let(:short_pubid) { "NIST IR 6969e2018" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 84-2946" do
    let(:original_pubid) { "NIST IR 84-2946" }
    let(:short_pubid) { "NIST IR 84-2946" }

    it_behaves_like "converts pubid to different formats"
  end
end
