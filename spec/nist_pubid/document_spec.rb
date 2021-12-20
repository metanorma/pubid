# frozen_string_literal: true

RSpec.describe NistPubid::Document do
  let(:short_pubid) { "NIST SP 800-53-5" }
  let(:mr_pubid) { short_pubid.gsub(" ", ".") }
  let(:long_pubid) { nil }
  let(:abbrev_pubid) { nil }

  it "parses NIST PubID using parameters" do
    expect(described_class.new(publisher: "NIST", serie: "NIST SP",
                               docnumber: "800-53", revision: 5).to_s(:mr))
      .to eq(mr_pubid)
  end

  describe "generate NIST PubID string outputs" do
    subject { described_class.parse(original_pubid) }

    let(:original_pubid) { short_pubid }

    it "parses MR NIST PubID" do
      expect(described_class.parse(mr_pubid).to_s(:short)).to eq(short_pubid)
    end

    shared_examples "converts pubid to different formats" do
      it "converts into long Full PubID" do
        expect(subject.to_s(:long)).to eq(long_pubid) if long_pubid
      end

      it "converts into Abbreviated PubID" do
        expect(subject.to_s(:abbrev)).to eq(abbrev_pubid) if abbrev_pubid
      end

      it "converts into Short PubID" do
        expect(subject.to_s(:short)).to eq(short_pubid)
      end

      it "converts into Machine-readable PubID" do
        expect(subject.to_s(:mr)).to eq(mr_pubid)
      end
    end

    context "when NIST SP 800-53r5" do
      let(:long_pubid) do
        "National Institute of Standards and Technology Special Publication"\
          " 800-53, Revision 5"
      end
      let(:abbrev_pubid) do
        "Natl. Inst. Stand. Technol. Spec. Publ. 800-53, Rev. 5"
      end
      it_behaves_like "converts pubid to different formats"
    end

    context "when published by NBS" do
      let(:short_pubid) { "NBS SP 800-53-5" }
      let(:long_pubid) do
        "National Bureau of Standards Special Publication 800-53, Revision 5"
      end
      let(:abbrev_pubid) { "Natl. Bur. Stand. Spec. Publ. 800-53, Rev. 5" }

      it_behaves_like "converts pubid to different formats"
    end

    context "when NIST NCSTAR serie" do
      let(:short_pubid) { "NIST NCSTAR 1-1Cv1" }
      let(:long_pubid) do
        "National Institute of Standards and Technology National Construction"\
          " Safety Team Report 1-1C, Volume 1"
      end
      let(:abbrev_pubid) do
        "Natl. Inst. Stand. Technol. Natl. Constr. Tm. Act Rpt. 1-1C, Vol. 1"
      end

      it_behaves_like "converts pubid to different formats"
    end

    context "when with part" do
      let(:short_pubid) { "NIST SP 800-57pt1r4" }
      let(:long_pubid) do
        "National Institute of Standards and Technology Special Publication"\
          " 800-57 Part 1, Revision 4"
      end
      let(:abbrev_pubid) do
        "Natl. Inst. Stand. Technol. Spec. Publ. 800-57 Pt. 1, Rev. 4"
      end

      it_behaves_like "converts pubid to different formats"
    end

    context "when with update" do
      let(:original_pubid) { "NIST SP 800-53r4/Upd3-2015" }
      let(:short_pubid) { "NIST SP 800-53-4/Upd3-2015" }
      let(:long_pubid) do
        "National Institute of Standards and Technology Special Publication "\
          "800-53, Revision 4 Update 3-2015"
      end
      let(:abbrev_pubid) do
        "Natl. Inst. Stand. Technol. Spec. Publ. 800-53, Rev. 4 Upd. 3-2015"
      end
      let(:mr_pubid) { "NIST.SP.800-53-4.u3-2015" }

      it_behaves_like "converts pubid to different formats"
    end

    context "when with translation" do
      let(:short_pubid) { "NIST IR 8115(esp)" }
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

    context "when with addendum" do
      let(:short_pubid) { "NIST SP 800-38A Addendum" }
      let(:long_pubid) do
        "Addendum to National Institute of Standards and Technology Special"\
          " Publication 800-38A"
      end
      let(:abbrev_pubid) do
        "Add. to Natl. Inst. Stand. Technol. Spec. Publ. 800-38A"
      end
      let(:mr_pubid) { "NIST.SP.800-38A.add-1" }

      it_behaves_like "converts pubid to different formats"

      it "converts MR PubID into long Full PubID" do
        expect(described_class.parse(mr_pubid).to_s(:long)).to eq(long_pubid)
      end
    end

    context "when with stage" do
      let(:short_pubid) { "NIST SP(IPD) 800-53-5" }
      let(:long_pubid) do
        "National Institute of Standards and Technology Special Publication "\
          "Initial Public Draft 800-53, Revision 5"
      end
      let(:abbrev_pubid) do
        "Natl. Inst. Stand. Technol. Spec. Publ. Initial Public Draft 800-53,"\
          " Rev. 5"
      end
      let(:mr_pubid) { "NIST.SP.IPD.800-53-5" }

      it_behaves_like "converts pubid to different formats"
    end

    context "when with edition" do
      let(:short_pubid) { "NIST SP(IPD) 800-53e5" }
      let(:long_pubid) do
        "National Institute of Standards and Technology Special Publication "\
          "Initial Public Draft 800-53 Edition 5"
      end
      let(:abbrev_pubid) do
        "Natl. Inst. Stand. Technol. Spec. Publ. Initial Public Draft 800-53 "\
          "Ed. 5"
      end
      let(:mr_pubid) { "NIST.SP.IPD.800-53e5" }

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

    context "parse NBS CRPL-F-B series" do
      let(:original_pubid) { "NBS CRPL-F-B150" }
      let(:short_pubid) { "NBS CRPL-F-B 150" }
      let(:long_pubid) do
        "National Bureau of Standards CRPL Solar-Geophysical"\
          " Data 150"
      end
      let(:abbrev_pubid) do
        "Natl. Bur. Stand. CRPL Solar-Geophysical Data 150"
      end

      it_behaves_like "converts pubid to different formats"
    end

    context "parse NBS CRPL-F-B245 series" do
      let(:original_pubid) { "NBS CRPL-F-B245" }
      let(:short_pubid) { "NBS CRPL-F-B 245" }
      let(:long_pubid) do
        "National Bureau of Standards CRPL Solar-Geophysical"\
          " Data 245"
      end
      let(:abbrev_pubid) do
        "Natl. Bur. Stand. CRPL Solar-Geophysical Data 245"
      end

      it_behaves_like "converts pubid to different formats"
    end

    context "parse old NBS FIPS series" do
      let(:original_pubid) { "NBS FIPS 100" }
      let(:short_pubid) { "NBS FIPS PUB 100" }
      let(:long_pubid) do
        "National Bureau of Standards Federal Information Processing Standards"\
          " Publication 100"
      end
      let(:abbrev_pubid) do
        "Natl. Bur. Stand. Federal Inf. Process. Stds. 100"
      end

      it_behaves_like "converts pubid to different formats"
    end

    context "parse new NBS FIPS series" do
      let(:original_pubid) { "NBS FIPS PUB 100" }
      let(:short_pubid) { "NBS FIPS PUB 100" }
      let(:long_pubid) do
        "National Bureau of Standards Federal Information Processing Standards"\
          " Publication 100"
      end
      let(:abbrev_pubid) do
        "Natl. Bur. Stand. Federal Inf. Process. Stds. 100"
      end

      it_behaves_like "converts pubid to different formats"
    end

    context "parse old NIST FIPS series" do
      let(:original_pubid) { "NIST FIPS 140-3" }
      let(:short_pubid) { "NIST FIPS PUB 140-3" }
      let(:long_pubid) do
        "National Institute of Standards and Technology Federal Information"\
          " Processing Standards Publication 140-3"
      end
      let(:abbrev_pubid) do
        "Natl. Inst. Stand. Technol. Federal Inf. Process. Stds. 140-3"
      end

      it_behaves_like "converts pubid to different formats"
    end

    context "parse old NBS MONO series" do
      let(:original_pubid) { "NBS MONO 158" }
      let(:short_pubid) { "NBS MN 158" }
      let(:long_pubid) do
        "National Bureau of Standards Monograph 158"
      end
      let(:abbrev_pubid) do
        "Natl. Bur. Stand. Monogr. 158"
      end

      it_behaves_like "converts pubid to different formats"
    end

    context "parse old NIST MONO series" do
      let(:original_pubid) { "NIST MONO 178" }
      let(:short_pubid) { "NIST MN 178" }
      let(:long_pubid) do
        "National Institute of Standards and Technology Monograph 178"
      end
      let(:abbrev_pubid) do
        "Natl. Inst. Stand. Technol. Monogr. 178"
      end

      it_behaves_like "converts pubid to different formats"
    end

    context "parse NBS CSM series" do
      let(:original_pubid) { "NBS CSM v6n1" }
      let(:short_pubid) { "NBS CSM 6-1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "parse NIST SP 1190GB-1" do
      let(:short_pubid) { "NIST SP 1190GB-1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "parse NIST SP 304a-2017" do
      let(:original_pubid) { "NIST SP 304a-2017" }
      let(:short_pubid) { "NIST SP 304A-2017" }

      it_behaves_like "converts pubid to different formats"
    end

    context "parse NIST SP 500-202p2" do
      let(:original_pubid) { "NIST SP 500-202p2" }
      let(:short_pubid) { "NIST SP 500-202pt2" }

      it_behaves_like "converts pubid to different formats"
    end

    context "parse NIST SP 800-22r1a" do
      let(:original_pubid) { "NIST SP 800-22r1a" }
      let(:short_pubid) { "NIST SP 800-22-1a" }

      it_behaves_like "converts pubid to different formats"
    end

    context "parse NIST SP 800-60ver2v2" do
      let(:short_pubid) { "NIST SP 800-60ver2v2" }
      let(:short_pubid) { "NIST SP 800-60v2ver2" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 800-63v1.0.2" do
      let(:original_pubid) { "NIST SP 800-63v1.0.2" }
      let(:short_pubid) { "NIST SP 800-63ver1.0.2" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 305supp26" do
      let(:original_pubid) { "NIST SP 305supp26" }
      let(:short_pubid) { "NIST SP 305sup26" }
      let(:long_pubid) do
        "National Institute of Standards and Technology Special Publication "\
          "305 Supplement 26"
      end
      let(:abbrev_pubid) do
        "Natl. Inst. Stand. Technol. Spec. Publ. 305 Suppl. 26"
      end

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 260-162 2006ed." do
      let(:original_pubid) { "NIST SP 260-162 2006ed." }
      let(:short_pubid) { "NIST SP 260-162e2006" }
      let(:mr_pubid) { "NIST.SP.260-162e2006" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 500-300-upd" do
      let(:original_pubid) { "NIST SP 500-300-upd" }
      let(:short_pubid) { "NIST SP 500-300/Upd1" }
      let(:mr_pubid) { "NIST.SP.500-300.u1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 800-90b" do
      let(:original_pubid) { "NIST SP 800-90b" }
      let(:short_pubid) { "NIST SP 800-90B" }

      it_behaves_like "converts pubid to different formats"
    end

    # 800-85A-4 but 800-85Apt1r4
    context "NIST SP 800-85A-4" do
      let(:short_pubid) { "NIST SP 800-85A-4" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS RPT 9350sup" do
      let(:original_pubid) { "NBS RPT 9350sup" }
      let(:short_pubid) { "NBS RPT 9350sup" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS report ; 8079" do
      it "should raise error" do
        expect { described_class.parse("NBS report ; 8079") }
          .to raise_error(NistPubid::Errors::ParseError)
      end
    end

    context "NBS.RPT.8079" do
      let(:original_pubid) { "NBS.RPT.8079" }
      let(:short_pubid) { "NBS RPT 8079" }
      let(:mr_pubid) { "NBS.RPT.8079" }

      it_behaves_like "converts pubid to different formats"
    end

    context "when cannot parse serie" do
      it "should raise error" do
        expect { described_class.parse("NIST WRONG-SERIE 800-11") }
          .to raise_error(NistPubid::Errors::ParseError)
      end
    end

    context "when cannot parse code" do
      it "should raise error" do
        expect { described_class.parse("NIST SP WRONG-CODE") }
          .to raise_error(NistPubid::Errors::ParseError)
      end
    end
  end

  describe "access to PubID object" do
    it "returns revision" do
      expect(described_class.parse(short_pubid).revision).to eq("5")
    end

    it "can update revision" do
      pub_id = described_class.parse(short_pubid)
      pub_id.revision = 6
      expect(pub_id.to_s(:mr)).to eq("NIST.SP.800-53-6")
    end
  end
end
