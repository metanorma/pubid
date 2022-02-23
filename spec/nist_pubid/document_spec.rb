# frozen_string_literal: true

RSpec.describe NistPubid::Document do
  let(:short_pubid) { "NIST SP 800-53r5" }
  let(:mr_pubid) { short_pubid.gsub(" ", ".") }
  let(:long_pubid) { nil }
  let(:abbrev_pubid) { nil }

  it "parses NIST PubID using parameters" do
    expect(described_class.new(publisher: NistPubid::Publisher.new(publisher: "NIST"),
                               serie: NistPubid::Serie.new(serie: "NIST SP"),
                               docnumber: "800-53", revision: 5).to_s(:mr))
      .to eq(mr_pubid)
  end

  describe "generate NIST PubID string outputs" do
    subject { described_class.parse(original_pubid) }

    let(:original_pubid) { short_pubid }

    it "parses MR NIST PubID" do
      expect(described_class.parse(mr_pubid).to_s(:short)).to eq(short_pubid)
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

      context "when JSON output format" do
        it "generates json output" do
          expect(JSON.parse(subject.to_json))
            .to eq({
                     "styles" => {
                       "short" => short_pubid,
                       "abbrev" => abbrev_pubid,
                       "long" => long_pubid,
                       "mr" => mr_pubid,
                     },
                     "publisher" => "NIST",
                     "serie" => "NIST SP",
                     "code" => "800-53",
                     "revision" => "5",
                   })
        end
      end
    end

    context "when NIST NCSTAR serie" do
      let(:original_pubid) { "NIST NCSTAR 1-1Cv1" }
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
      let(:short_pubid) { "NIST SP 800-53r4/Upd3-2015" }
      let(:long_pubid) do
        "National Institute of Standards and Technology Special Publication "\
          "800-53, Revision 4 Update 3-2015"
      end
      let(:abbrev_pubid) do
        "Natl. Inst. Stand. Technol. Spec. Publ. 800-53, Rev. 4 Upd. 3-2015"
      end
      let(:mr_pubid) { "NIST.SP.800-53r4.u3-2015" }

      it_behaves_like "converts pubid to different formats"
    end

    context "when with translation" do
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

    context "when with addendum" do
      let(:original_pubid) { "NIST SP 800-38a-add" }
      let(:short_pubid) { "NIST SP 800-38A Add." }
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
      let(:short_pubid) { "NIST SP(IPD) 800-53r5" }
      let(:long_pubid) do
        "National Institute of Standards and Technology Special Publication "\
          "Initial Public Draft 800-53, Revision 5"
      end
      let(:abbrev_pubid) do
        "Natl. Inst. Stand. Technol. Spec. Publ. Initial Public Draft 800-53,"\
          " Rev. 5"
      end
      let(:mr_pubid) { "NIST.SP.IPD.800-53r5" }

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
      let(:short_pubid) { "NBS FIPS 100" }
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
      let(:original_pubid) { "NBS FIPS 100" }
      let(:short_pubid) { "NBS FIPS 100" }
      let(:mr_pubid) { "NBS.FIPS.100" }
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
      let(:mr_pubid) { "NIST.FIPS.140-3" }
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

    context "NBS CSM 1" do
      let(:original_pubid) { "NBS CSM 1" }
      let(:short_pubid) { "NBS CSM 1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "parse NIST SP 1190GB-1" do
      let(:original_pubid) { "NIST SP 1190GBe1" }
      let(:short_pubid) { "NIST SP 1190GBe1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "parse NIST SP 304a-2017" do
      let(:original_pubid) { "NIST SP 304a-2017" }
      let(:short_pubid) { "NIST SP 304Ae2017" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 330-2019" do
      let(:original_pubid) { "NIST SP 330-2019" }
      let(:short_pubid) { "NIST SP 330e2019" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 777-1990" do
      let(:original_pubid) { "NIST SP 777-1990" }
      let(:short_pubid) { "NIST SP 777e1990" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 782-1995-96" do
      let(:original_pubid) { "NIST SP 782-1995-96" }
      let(:short_pubid) { "NIST SP 782e1995" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 250-1039" do
      let(:original_pubid) { "NIST SP 250-1039" }
      let(:short_pubid) { "NIST SP 250-1039" }

      it_behaves_like "converts pubid to different formats"
    end

    context "parse NIST SP 500-202p2" do
      let(:original_pubid) { "NIST SP 500-202p2" }
      let(:short_pubid) { "NIST SP 500-202pt2" }

      it_behaves_like "converts pubid to different formats"
    end

    context "parse NIST SP 800-22r1a" do
      let(:original_pubid) { "NIST SP 800-22r1a" }
      let(:short_pubid) { "NIST SP 800-22r1a" }

      it_behaves_like "converts pubid to different formats"
    end

    context "parse NIST SP 800-60ver2v2" do
      let(:original_pubid) { "NIST SP 800-60ver2v2" }
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

    context "NIST SP 955 Suppl." do
      let(:original_pubid) { "NIST SP 955 Suppl." }
      let(:short_pubid) { "NIST SP 955sup" }

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
      let(:short_pubid) { "NIST SP 500-300/Upd1-202105" }
      let(:mr_pubid) { "NIST.SP.500-300.u1-202105" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 800-90b" do
      let(:original_pubid) { "NIST SP 800-90b" }
      let(:short_pubid) { "NIST SP 800-90B" }

      it_behaves_like "converts pubid to different formats"
    end

    # 800-85A-4 but 800-85Apt1r4
    context "NIST SP 800-85A-4" do
      let(:original_pubid) { "NIST SP 800-85A-4" }
      let(:short_pubid) { "NIST SP 800-85Ar4" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 800-56Ar2" do
      let(:short_pubid) { "NIST SP 800-56Ar2" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 800-56Cr1" do
      let(:short_pubid) { "NIST SP 800-56Cr1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 800-56ar" do
      let(:original_pubid) { "NIST SP 800-56ar" }
      let(:short_pubid) { "NIST SP 800-56Ar1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS RPT 9350sup" do
      let(:original_pubid) { "NBS RPT 9350sup" }
      let(:short_pubid) { "NBS RPT 9350sup" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS report ; 8079" do
      let(:original_pubid) { "NBS report ; 8079" }
      let(:short_pubid) { "NBS RPT 8079" }
      let(:mr_pubid) { "NBS.RPT.8079" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS.RPT.8079" do
      let(:original_pubid) { "NBS.RPT.8079" }
      let(:short_pubid) { "NBS RPT 8079" }
      let(:mr_pubid) { "NBS.RPT.8079" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 1262es" do
      let(:original_pubid) { "NIST SP 1262es" }
      let(:short_pubid) { "NIST SP 1262(spa)" }
      let(:mr_pubid) { "NIST.SP.1262.spa" }

      it_behaves_like "converts pubid to different formats"
    end

    context "LCIRC 887" do
      let(:original_pubid) { "NBS.LCIRC.887" }
      let(:short_pubid) { "NBS LC 887" }
      let(:mr_pubid) { "NBS.LC.887" }

      it_behaves_like "converts pubid to different formats"
    end

    context "LCIRC 888r1964" do
      let(:original_pubid) { "NBS.LCIRC.888r1964" }
      let(:short_pubid) { "NBS LC 888r1964" }
      let(:mr_pubid) { "NBS.LC.888r1964" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 800-38e" do
      let(:original_pubid) { "NIST SP 800-38e" }
      let(:short_pubid) { "NIST SP 800-38E" }

      it_behaves_like "converts pubid to different formats"
    end

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

    context "NBS CRPL 4-m-5" do
      let(:original_pubid) { "NBS CRPL 4-m-5" }
      let(:short_pubid) { "NBS CRPL 4-M-5" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS IR 80-2073.3" do
      let(:original_pubid) { "NBS IR 80-2073.3" }
      let(:short_pubid) { "NBS IR 80-2073.3" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS MP 39(1)" do
      let(:original_pubid) { "NBS MP 39(1)" }
      let(:short_pubid) { "NBS MP 39e1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 1075-NCNR" do
      let(:short_pubid) { "NIST SP 1075-NCNR" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS SP 250e1982app" do
      let(:short_pubid) { "NBS SP 250e1982app" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 260-126 rev 2013" do
      let(:original_pubid) { "NIST SP 260-126 rev 2013" }
      let(:short_pubid) { "NIST SP 260-126r2013" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 800-27ra" do
      let(:original_pubid) { "NIST SP 800-27ra" }
      let(:short_pubid) { "NIST SP 800-27ra" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 800-53ar1" do
      let(:original_pubid) { "NIST SP 800-53ar1" }
      let(:short_pubid) { "NIST SP 800-53Ar1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 800-53Ar4" do
      let(:short_pubid) { "NIST SP 800-53Ar4" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 800-57Pt3r1" do
      let(:original_pubid) { "NIST SP 800-57Pt3r1" }
      let(:short_pubid) { "NIST SP 800-57pt3r1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 801-errata" do
      let(:original_pubid) { "NIST SP 801-errata" }
      let(:short_pubid) { "NIST SP 801err" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 955 Suppl." do
      let(:original_pubid) { "NIST SP 955 Suppl." }
      let(:short_pubid) { "NIST SP 955sup" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST LC 1136" do
      it "should raise error" do
        expect { described_class.parse("LCIRC 1136") }
          .to raise_error(NistPubid::Errors::ParseError)
      end
    end

    context "NIST.LCIRC.1136" do
      let(:original_pubid) { "NIST.LCIRC.1136" }
      let(:short_pubid) { "NIST LC 1136" }
      let(:mr_pubid) { "NIST.LC.1136" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST GCR 17-917-45" do
      let(:original_pubid) { "NIST GCR 17-917-45" }
      let(:short_pubid) { "NIST GCR 17-917-45" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS FIPS 1-2-1974" do
      let(:original_pubid) { "NBS FIPS 1-2-1974" }
      let(:short_pubid) { "NBS FIPS 1-2e1974" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS CIRC 74errata" do
      let(:original_pubid) { "NBS CIRC 74errata" }
      let(:short_pubid) { "NBS CIRC 74err" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS FIPS 14-1971" do
      let(:original_pubid) { "NBS FIPS 14-1971" }
      let(:short_pubid) { "NBS FIPS 14-1971" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS CIRC 54index" do
      let(:original_pubid) { "NBS CIRC 54index" }
      let(:short_pubid) { "NBS CIRC 54indx" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS FIPS 14-1-Dec1980" do
      let(:original_pubid) { "NBS FIPS 14-1-Dec1980" }
      let(:short_pubid) { "NBS FIPS 14-1e198012" }

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

    context "NIST.CSWP.01162020pt" do
      let(:original_pubid) { "NIST.CSWP.01162020pt" }
      let(:short_pubid) { "NIST CSRC White Paper 01162020(por)" }
      let(:mr_pubid) { "NIST.CSWP.01162020.por" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST CSWP 04162018pt" do
      let(:original_pubid) { "NIST CSWP 04162018pt" }
      let(:short_pubid) { "NIST CSRC White Paper 04162018(por)" }
      let(:mr_pubid) { "NIST.CSWP.04162018.por" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST CSWP 01162020id" do
      let(:original_pubid) { "NIST CSWP 01162020id" }
      let(:short_pubid) { "NIST CSRC White Paper 01162020(ind)" }
      let(:mr_pubid) { "NIST.CSWP.01162020.ind" }

      it_behaves_like "converts pubid to different formats"
    end

    context "when cannot parse serie" do
      it "should raise error" do
        expect { described_class.parse("NIST WRONG-SERIE 800-11") }
          .to raise_error(NistPubid::Errors::ParseError)
      end
    end

    context "NIST CSWP 01142020" do
      let(:original_pubid) { "NIST CSWP 01142020" }
      let(:short_pubid) { "NIST CSRC White Paper 01142020" }
      let(:mr_pubid) { "NIST.CSWP.01142020" }

      it_behaves_like "converts pubid to different formats"
    end



    # context "NIST Monograph 175" do
    #   let(:original_pubid) { "NIST Monograph 175" }
    #   let(:short_pubid) { "NIST MN 175" }
    #
    #   it_behaves_like "converts pubid to different formats"
    # end

    context "NBS FIPS 107-Mar1985" do
      let(:original_pubid) { "NBS FIPS 107-Mar1985" }
      let(:short_pubid) { "NBS FIPS 107e198503" }

      it_behaves_like "converts pubid to different formats"

      it "has edition" do
        expect(subject.edition.to_s).to eq("198503")
        expect(subject.edition.year).to eq(1985)
        expect(subject.edition.month).to eq(3)
      end
    end

    # context "National Institute of Standards and Technology Monograph 175" do
    #   let(:original_pubid) { "National Institute of Standards and Technology Monograph 175" }
    #   let(:short_pubid) { "NIST MN 175" }
    #
    #   it_behaves_like "converts pubid to different formats"
    # end

    context "NBS FIPS 107-Feb1985" do
      let(:original_pubid) { "NBS FIPS 107-Feb1985" }
      let(:short_pubid) { "NBS FIPS 107e198502" }

      it_behaves_like "converts pubid to different formats"
    end

    # context "National Bureau of Standards Monograph 175" do
    #   let(:original_pubid) { "National Bureau of Standards Monograph 175" }
    #   let(:short_pubid) { "NBS MN 175" }
    #
    #   it_behaves_like "converts pubid to different formats"
    # end

    context "NBS FIPS 11-1-Sep1977" do
      let(:original_pubid) { "NBS FIPS 11-1-Sep1977" }
      let(:short_pubid) { "NBS FIPS 11-1e197709" }

      it_behaves_like "converts pubid to different formats"
    end

    # context "National Institute of Standards and Technology Special Publication "\
    #         "800-53, Revision 4 Update 3-2015" do
    #   let(:original_pubid) do
    #     "National Institute of Standards and Technology Special Publication "\
    #       "800-53, Revision 4 Update 3-2015"
    #   end
    #   let(:short_pubid) { "NIST SP 800-53r4/Upd3-2015" }
    #   let(:mr_pubid) { "NIST.SP.800-53r4.u3-2015" }
    #
    #   it_behaves_like "converts pubid to different formats"
    # end

    # context "National Institute of Standards and Technology Special"\
    #         "  800-53 Edition 5" do
    #   let(:original_pubid) do
    #     "National Institute of Standards and Technology Special Publication "\
    #       "800-53 Edition 5"
    #   end
    #   let(:long_pubid) { original_pubid }
    #   let(:short_pubid) { "NIST SP 800-53e5" }
    #
    #   it_behaves_like "converts pubid to different formats"
    # end
    #
    # context "Natl. Bur. Stand. Federal Inf. Process. Stds. 100" do
    #   let(:original_pubid) do
    #     "Natl. Bur. Stand. Federal Inf. Process. Stds. 100"
    #   end
    #   let(:short_pubid) { "NBS FIPS 100" }
    #   let(:long_pubid) do
    #     "National Bureau of Standards Federal Information Processing Standards"\
    #       " Publication 100"
    #   end
    #
    #   it_behaves_like "converts pubid to different formats"
    # end

    context "NBS FIPS 11-1-Sep30" do
      let(:original_pubid) { "NBS FIPS 11-1-Sep30" }
      # has doi NBS.FIPS.11-1-Sep30/1977
      let(:short_pubid) { "NBS FIPS 11-1e19770930" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS.CS.e104-43" do
      let(:original_pubid) { "NBS.CS.e104-43" }
      # has doi NBS.FIPS.11-1-Sep30/1977
      let(:short_pubid) { "NBS CS-E 104-43" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS CRPL c4-4" do
      let(:original_pubid) { "NBS CRPL c4-4" }
      # has doi NBS.FIPS.11-1-Sep30/1977
      let(:short_pubid) { "NBS CRPL 4-4" }
      it_behaves_like "converts pubid to different formats"
    end

    context "NBS CRPL 1-2_3-1" do
      let(:original_pubid) { "NBS CRPL 1-2_3-1" }
      let(:short_pubid) { "NBS CRPL 1-2pt3-1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS CRPL 1-2_3-1A" do
      let(:original_pubid) { "NBS CRPL 1-2_3-1A" }
      let(:short_pubid) { "NBS CRPL 1-2pt3-1supA" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST TN 1297-1993" do
      let(:original_pubid) { "NIST TN 1297-1993" }
      let(:short_pubid) { "NIST TN 1297e1993" }

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

    context "NIST AMS 300-8r1 (February 2021 update)" do
      let(:original_pubid) { "NIST AMS 300-8r1 (February 2021 update)" }
      let(:short_pubid) { "NIST AMS 300-8r1/Upd1-201502" }
      let(:mr_pubid) { "NIST.AMS.300-8r1.u1-201502" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST TN 2150-upd" do
      let(:original_pubid) { "NIST TN 2150-upd" }
      let(:short_pubid) { "NIST TN 2150/Upd1-202102" }
      let(:mr_pubid) { "NIST.TN.2150.u1-202102" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS report ; Oct-Dec1950" do
      let(:original_pubid) { "NBS report ; Oct-Dec1950" }
      let(:short_pubid) { "NBS RPT Oct-Dec1950" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS RPT ADHOC" do
      let(:original_pubid) { "NBS RPT ADHOC" }
      let(:short_pubid) { "NBS RPT ADHOC" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS report ; div9" do
      let(:original_pubid) { "NBS report ; div9" }
      let(:short_pubid) { "NBS RPT div9" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST FIPS 54-1-Jan15" do
      let(:original_pubid) { "NIST FIPS 54-1-Jan15" }
      let(:short_pubid) { "NIST FIPS PUB 54-1" }
      let(:mr_pubid) { "NIST.FIPS.54-1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS SP 535v2a-l" do
      let(:original_pubid) { "NBS SP 535v2a-l" }
      let(:short_pubid) { "NBS SP 535v2a-l" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST GCR 21-917-48v3B" do
      let(:original_pubid) { "NIST GCR 21-917-48v3B" }
      let(:short_pubid) { "NIST GCR 21-917-48v3B" }

      it_behaves_like "converts pubid to different formats"
    end

    context "LCIRC 1088sp" do
      let(:original_pubid) { "NBS.LCIRC.1088sp" }
      let(:short_pubid) { "NBS LC 1088(spa)" }
      let(:mr_pubid) { "NBS.LC.1088.spa" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS.SP.428P1" do
      let(:original_pubid) { "NBS.SP.428P1" }
      let(:short_pubid) { "NBS SP 428pt1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS CIRC 24supJan1924" do
      let(:original_pubid) { "NBS CIRC 24supJan1924" }
      let(:short_pubid) { "NBS CIRC 24e192401sup" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS HB 67suppFeb1965" do
      let(:original_pubid) { "NBS HB 67suppFeb1965" }
      let(:short_pubid) { "NBS HB 67e196502sup" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS IR 74-577-1" do
      let(:original_pubid) { "NBS IR 74-577-1" }
      let(:short_pubid) { "NBS IR 74-577v1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS.LCIRC.118sup12/1926" do
      let(:original_pubid) { "NBS.LCIRC.118sup12/1926" }
      let(:short_pubid) { "NBS LC 118sup/Upd1-192612" }
      let(:mr_pubid) { "NBS.LC.118sup.u1-192612" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS IR 79-1591-1" do
      let(:original_pubid) { "NBS IR 79-1591-1" }
      let(:short_pubid) { "NBS IR 79-1591pt1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS IR 80-2111-1" do
      let(:original_pubid) { "NBS IR 80-2111-1" }
      let(:short_pubid) { "NBS IR 80-2111pt1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS IR 84-2857-1" do
      let(:original_pubid) { "NBS IR 84-2857-1" }
      let(:short_pubid) { "NBS IR 84-2857pt1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS.LCIRC.145r11/1925" do
      let(:original_pubid) { "NBS.LCIRC.145r11/1925" }
      let(:short_pubid) { "NBS LC 145/Upd1-192511" }
      let(:mr_pubid) { "NBS.LC.145.u1-192511" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST FIPS 150-Aug1988" do
      let(:original_pubid) { "NIST FIPS 150-Aug1988" }
      let(:short_pubid) { "NIST FIPS PUB 150e198808" }
      let(:mr_pubid) { "NIST.FIPS.150e198808" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST HB 105-1-1990" do
      let(:original_pubid) { "NIST HB 105-1-1990" }
      let(:short_pubid) { "NIST HB 105-1r1990" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS.HB.105-1r1990" do
      let(:original_pubid) { "NBS.HB.105-1r1990" }
      let(:short_pubid) { "NIST HB 105-1r1990" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS BH 3a" do
      let(:original_pubid) { "NBS BH 3a" }
      let(:short_pubid) { "NBS BH 3A" }

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

    context "NBS CRPL-F-A 135B" do
      let(:original_pubid) { "NBS CRPL-F-A 135B" }
      let(:short_pubid) { "NBS CRPL-F-A 135B" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS CS 102E-42" do
      let(:original_pubid) { "NBS CS 102E-42" }
      let(:short_pubid) { "NBS CS 102E-42" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST HB 105-2e1996" do
      let(:original_pubid) { "NIST HB 105-2e1996" }
      let(:short_pubid) { "NIST HB 105-2e1996" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS HB 67suppJune1965" do
      let(:original_pubid) { "NBS HB 67suppJune1965" }
      let(:short_pubid) { "NBS HB 67e196506sup" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS IR 73-285p1" do
      let(:original_pubid) { "NBS IR 73-285p1" }
      let(:short_pubid) { "NBS IR 73-285pt1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS IR 80-2111-11" do
      let(:original_pubid) { "NBS IR 80-2111-11" }
      let(:short_pubid) { "NBS IR 80-2111pt11" }

      it_behaves_like "converts pubid to different formats"
    end

    context "LCIRC 118sup3/1926" do
      let(:original_pubid) { "NBS.LCIRC.118sup3/1926" }
      let(:short_pubid) { "NBS LC 118sup/Upd1-192603" }
      let(:mr_pubid) { "NBS.LC.118sup.u1-192603" }

      it_behaves_like "converts pubid to different formats"
    end

    context "LCIRC 145r6/1925" do
      let(:original_pubid) { "NBS.LCIRC.145r6/1925" }
      let(:short_pubid) { "NBS LC 145/Upd1-192506" }
      let(:mr_pubid) { "NBS.LC.145.u1-192506" }

      it_behaves_like "converts pubid to different formats"
    end

    context "LCIRC 378b" do
      let(:original_pubid) { "NBS.LCIRC.378b" }
      let(:short_pubid) { "NBS LC 378B" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS MONO 128p1" do
      let(:original_pubid) { "NBS MONO 128p1" }
      let(:short_pubid) { "NBS MN 128pt1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS NSRDS 61p1" do
      let(:original_pubid) { "NBS.NSRDS.61p1" }
      let(:short_pubid) { "NSRDS-NBS 61pt1" }
      let(:mr_pubid) { "NBS.NSRDS.61pt1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS report ; 1946-1947" do # NBS.RPT.1946-1947
      let(:original_pubid) { "NBS.RPT.1946-1947" }
      let(:short_pubid) { "NBS RPT 1946-1947" }
      let(:mr_pubid) { "NBS.RPT.1946-1947" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST SP 1011-I-2.0" do

    end

    context "NIST SP 1011-II-1.0" do

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
      expect(pub_id.to_s(:mr)).to eq("NIST.SP.800-53r6")
    end
  end

  describe "returns weight of PubID object" do
    it "should return more weight for more complete PubID" do
      expect(described_class.parse("NIST SP 260-162").weight).to be <
        described_class.parse("NIST SP 260-162 2006ed.").weight
    end
  end

  describe "#merge" do
    it "merges two documents" do
      expect(described_class.parse("NIST SP 260-162r1").merge(
        described_class.parse("NIST SP 260-162 2006ed.")
      ).to_s(:short)).to eq("NIST SP 260-162e2006r1")
    end

    context "NBS CIRC 74e1937" do
      it do
        expect(described_class.parse("NBS CIRC 74e1937").merge(
          described_class.parse("NBS.CIRC.74-1937")
        ).to_s(:short)).to eq("NBS CIRC 74e1937")
      end
    end

    context "NBS HB 44-1988" do
      it do
        expect(described_class.parse("NIST HB 44-1988").merge(
          described_class.parse("NBS.HB.44-1988")
        ).to_s(:short)).to eq("NBS HB 44e1988")
      end
    end

    context "NIST FIPS 100-1" do
      it do
        expect(described_class.parse("NIST FIPS 100-1").merge(
          described_class.parse("NBS.FIPS.100-1")
        ).to_s(:short)).to eq("NBS FIPS 100-1")
      end
    end

    context "NIST FIPS 130-1988" do
      it do
        expect(described_class.parse("NIST FIPS 130-1988").merge(
          described_class.parse("NBS.FIPS.130-1988")
        ).to_s(:short)).to eq("NBS FIPS 130-1988")
      end
    end

    context "NIST HB 105-1-1990" do
      it do
        expect(described_class.parse("NIST HB 105-1-1990").merge(
          described_class.parse("NBS.HB.105-1r1990")
        ).to_s(:short)).to eq("NIST HB 105-1r1990")
      end
    end

    context "NIST FIPS 100-1-1991" do
      it do
        expect(described_class.parse("NIST FIPS 100-1-1991").merge(
          described_class.parse("NBS.FIPS.100-1-1991")
        ).to_s(:short)).to eq("NIST FIPS PUB 100-1e1991")
      end
    end

    context "NBS FIPS 11-1-Sep1977" do
      it do
        expect(described_class.parse("NBS FIPS 11-1-Sep1977").merge(
          described_class.parse("NBS.FIPS.11-1-Sep1977")
        ).to_s(:short)).to eq("NBS FIPS 11-1e197709")
      end
    end

    context "NBS FIPS 16-1-1977" do
      it do
        expect(described_class.parse("NBS FIPS 16-1-1977").merge(
          described_class.parse("NBS.FIPS.16-1-1977")
        ).to_s(:short)).to eq("NBS FIPS 16-1e1977")
      end
    end

    context "NBS FIPS 68-2-Aug1987" do
      it do
        expect(described_class.parse("NBS FIPS 68-2-Aug1987").merge(
          described_class.parse("NBS.FIPS.68-2-Aug1987")
        ).to_s(:short)).to eq("NBS FIPS 68-2e198708")
      end
    end

    context "NBS FIPS 107-Mar1985" do
      it do
        expect(described_class.parse("NBS FIPS 107-Mar1985").merge(
          described_class.parse("NBS.FIPS.107-Mar1985")
        ).to_s(:short)).to eq("NBS FIPS 107e198503")
      end
    end

    context "NIST HB 133e4-2002" do
      it do
        expect(described_class.parse("NIST HB 133e4-2002").merge(
          described_class.parse("NIST.HB.133e4")
        ).to_s(:short)).to eq("NIST HB 133e4")
      end
    end

    context "NIST SP 260-126 rev 2013" do
      it do
        expect(described_class.parse("NIST SP 260-126 rev 2013").merge(
          described_class.parse("NIST.SP.260-126rev2013")
        ).to_s(:short)).to eq("NIST SP 260-126r2013")
      end
    end

    context "NIST FIPS 150-Aug1988" do
      it do
        expect(described_class.parse("NIST FIPS 150-Aug1988").merge(
          described_class.parse("NIST.FIPS.150-Aug1988")
        ).to_s(:short)).to eq("NIST FIPS PUB 150e198808")
      end
    end

    context "NBS FIPS 107-Feb1985" do
      it do
        expect(described_class.parse("NBS FIPS 107-Feb1985").merge(
          described_class.parse("NBS.FIPS.107-Feb1985")
        ).to_s(:short)).to eq("NBS FIPS 107e198502")
      end
    end

    context "NIST FIPS 54-1-Jan17" do
      it do
        expect(described_class.parse("NIST FIPS 54-1-Jan17").merge(
          described_class.parse("NIST.FIPS.54-1-Jan17/1991")
        ).to_s(:short)).to eq("NIST FIPS PUB 54-1e19910117")
      end
    end
  end
end
