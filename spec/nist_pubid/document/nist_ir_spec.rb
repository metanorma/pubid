RSpec.describe Pubid::Nist::Identifier do
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
    let(:short_pubid) { "NIST IR 4743/Upd1-199206" }
    let(:mr_pubid) { "NIST.IR.4743.u1-199206" }

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

  context "NISTIR 8115r1/upd" do
    let(:original_pubid) { "NISTIR 8115r1/upd" }
    let(:short_pubid) { "NIST IR 8115r1/Upd1-2021" }
    let(:mr_pubid) { "NIST.IR.8115r1.u1-2021" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NISTIR 8211-upd" do
    let(:original_pubid) { "NISTIR 8211-upd" }
    let(:short_pubid) { "NIST IR 8211/Upd1-2021" }
    let(:mr_pubid) { "NIST.IR.8211.u1-2021" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NISTIR 8259Aes" do
    let(:original_pubid) { "NISTIR 8259Aes" }
    let(:short_pubid) { "NIST IR 8259A(spa)" }
    let(:mr_pubid) { "NIST.IR.8259A.spa" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 4335r11/90" do
    let(:original_pubid) { "NIST IR 4335r11/90" }
    let(:short_pubid) { "NIST IR 4335/Upd1-199011" }
    let(:mr_pubid) { "NIST.IR.4335.u1-199011" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 5443-A" do
    let(:original_pubid) { "NIST IR 5443-A" }
    let(:short_pubid) { "NIST IR 5443-A" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 7297-B" do
    let(:original_pubid) { "NIST IR 7297-B" }
    let(:short_pubid) { "NIST IR 7297-B" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 6099a" do
    let(:original_pubid) { "NIST IR 6099a" }
    let(:short_pubid) { "NIST IR 6099A" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 7356-CAS" do
    let(:original_pubid) { "NIST IR 7356-CAS" }
    let(:short_pubid) { "NIST IR 7356-CAS" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 4335rNov1990" do
    let(:original_pubid) { "NIST IR 4335rNov1990" }
    let(:short_pubid) { "NIST IR 4335/Upd1-199011" }
    let(:mr_pubid) { "NIST.IR.4335.u1-199011" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 6945r" do
    let(:original_pubid) { "NIST IR 6945r" }
    let(:short_pubid) { "NIST IR 6945r1" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 7103b" do
    let(:original_pubid) { "NIST IR 7103b" }
    let(:short_pubid) { "NIST IR 7103B" }

    it_behaves_like "converts pubid to different formats"
  end

  context "NIST IR 8115(esp)" do
    let(:short_pubid) { "NIST IR 8115(esp)" }
    let(:mr_pubid) { "NIST.IR.8115.esp" }
    let(:long_pubid) do
      "National Institute of Standards and Technology Interagency or"\
          " Internal Report 8115 (ESP)"
    end
    let(:abbrev_pubid) do
      "Natl. Inst. Stand. Technol. Interagency or Internal Report"\
          " 8115 (ESP)"
    end

    it_behaves_like "converts pubid to different formats"
  end
end
