# frozen_string_literal: true
require "parslet/rig/rspec"

RSpec.describe Pubid::Nist::Identifier do
  let(:short_pubid) { "NIST SP 800-53r5" }
  let(:mr_pubid) { short_pubid.gsub(" ", ".") }
  let(:long_pubid) { nil }
  let(:abbrev_pubid) { nil }

  it "parses NIST PubID using parameters" do
    expect(described_class.new(publisher: Pubid::Nist::Publisher.new(publisher: "NIST"),
                               serie: Pubid::Nist::Serie.new(serie: "NIST SP"),
                               number: "800-53", revision: 5).to_s(:mr))
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
      let(:short_pubid) { "NIST FIPS 140-3" }
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
      let(:short_pubid) { "NBS CSM v6pt1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS CSM 1" do
      let(:original_pubid) { "NBS CSM 1" }
      let(:short_pubid) { "NBS CSM 1" }

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

    context "NBS SP 250e1982app" do
      let(:short_pubid) { "NBS SP 250e1982app" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST LC 1136" do
      it "should raise error" do
        expect { described_class.parse("LCIRC 1136") }
          .to raise_error(Pubid::Core::Errors::ParseError)
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

    context "NBS FIPS 14-1971" do
      let(:original_pubid) { "NBS FIPS 14-1971" }
      let(:short_pubid) { "NBS FIPS 14-1971" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS FIPS 14-1-Dec1980" do
      let(:original_pubid) { "NBS FIPS 14-1-Dec1980" }
      let(:short_pubid) { "NBS FIPS 14-1e198012" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST.CSWP.01162020pt" do
      let(:original_pubid) { "NIST.CSWP.01162020pt" }
      let(:short_pubid) { "NIST CSRC White Paper 01162020 por" }
      let(:mr_pubid) { "NIST.CSWP.01162020.por" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST CSWP 04162018pt" do
      let(:original_pubid) { "NIST CSWP 04162018pt" }
      let(:short_pubid) { "NIST CSRC White Paper 04162018 por" }
      let(:mr_pubid) { "NIST.CSWP.04162018.por" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST CSWP 01162020id" do
      let(:original_pubid) { "NIST CSWP 01162020id" }
      let(:short_pubid) { "NIST CSRC White Paper 01162020 ind" }
      let(:mr_pubid) { "NIST.CSWP.01162020.ind" }

      it_behaves_like "converts pubid to different formats"
    end

    context "when cannot parse serie" do
      it "should raise error" do
        expect { described_class.parse("NIST WRONG-SERIE 800-11") }
          .to raise_error(Pubid::Core::Errors::ParseError)
      end
    end

    context "NIST CSWP 01142020" do
      let(:original_pubid) { "NIST CSWP 01142020" }
      let(:short_pubid) { "NIST CSRC White Paper 01142020" }
      let(:mr_pubid) { "NIST.CSWP.01142020" }

      it_behaves_like "converts pubid to different formats"
    end

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

    context "NBS FIPS 107-Feb1985" do
      let(:original_pubid) { "NBS FIPS 107-Feb1985" }
      let(:short_pubid) { "NBS FIPS 107e198502" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS FIPS 11-1-Sep1977" do
      let(:original_pubid) { "NBS FIPS 11-1-Sep1977" }
      let(:short_pubid) { "NBS FIPS 11-1e197709" }

      it_behaves_like "converts pubid to different formats"
    end

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

    context "NBS FIPS 11-1-Sep30/1977" do
      let(:original_pubid) { "NBS FIPS 11-1-Sep30/1977" }
      let(:short_pubid) { "NBS FIPS 11-1e19770930" }
      let(:mr) { "NBS.FIPS.11-1e19770930" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS FIPS 89-Sep1" do
      let(:original_pubid) { "NBS FIPS 89-Sep1" }
      let(:short_pubid) { "NBS FIPS 89e198109" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS LCIRC 1" do
      let(:original_pubid) { "NBS LCIRC 1" }
      let(:short_pubid) { "NBS LC 1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS LCIRC 1013r1953" do
      let(:original_pubid) { "NBS LCIRC 1013r1953" }
      let(:short_pubid) { "NBS LC 1013r1953" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS LCIRC 378g" do
      let(:original_pubid) { "NBS LCIRC 378g" }
      let(:short_pubid) { "NBS LC 378G" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS NSRDS 1" do
      let(:original_pubid) { "NBS NSRDS 1" }
      let(:short_pubid) { "NSRDS-NBS 1" }
      let(:mr_pubid) { "NBS.NSRDS.1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS LCIRC 1088sp" do
      let(:original_pubid) { "NBS LCIRC 1088sp" }
      let(:short_pubid) { "NBS LC 1088 spa" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST HB 150-2d" do
      let(:original_pubid) { "NIST HB 150-2d" }
      let(:short_pubid) { "NIST HB 150-2D" }

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

    context "NIST AMS 300-8r1 (February 2021 update)" do
      let(:original_pubid) { "NIST AMS 300-8r1 (February 2021 update)" }
      let(:short_pubid) { "NIST AMS 300-8r1/Upd1-202102" }
      let(:mr_pubid) { "NIST.AMS.300-8r1.u1-202102" }

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
      let(:short_pubid) { "NIST FIPS 54-1" }
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
      let(:short_pubid) { "NBS LC 1088 spa" }
      let(:mr_pubid) { "NBS.LC.1088.spa" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS.SP.428P1" do
      let(:original_pubid) { "NBS.SP.428P1" }
      let(:short_pubid) { "NBS SP 428pt1" }

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
      let(:short_pubid) { "NIST FIPS 150e198808" }
      let(:mr_pubid) { "NIST.FIPS.150e198808" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST HB 105-1-1990" do
      let(:original_pubid) { "NIST HB 105-1-1990" }
      let(:short_pubid) { "NIST HB 105-1r1990" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS BH 3a" do
      let(:original_pubid) { "NBS BH 3a" }
      let(:short_pubid) { "NBS BH 3A" }

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

    context "NBS RPT 4817-A" do
      let(:original_pubid) { "NBS RPT 4817-A" }
      let(:short_pubid) { "NBS RPT 4817-A" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS RPT 7386a" do
      let(:original_pubid) { "NBS RPT 7386a" }
      let(:short_pubid) { "NBS RPT 7386a" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS SP 384r" do
      let(:original_pubid) { "NBS SP 384r" }
      let(:short_pubid) { "NBS SP 384r1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS TN 100-A" do
      let(:original_pubid) { "NBS TN 100-A" }
      let(:short_pubid) { "NBS TN 100-A" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS TN 467p1adde1" do
      let(:original_pubid) { "NBS TN 467p1adde1" }
      let(:short_pubid) { "NBS TN 467pt1 Add." }
      let(:mr_pubid) { "NBS.TN.467pt1.add-1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST HB 146v1-1991" do
      let(:original_pubid) { "NIST HB 146v1-1991" }
      let(:short_pubid) { "NIST HB 146v1e1991" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST HB 150-2A" do
      let(:original_pubid) { "NIST HB 150-2A" }
      let(:short_pubid) { "NIST HB 150-2A" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST NCSTAR 1-1b" do
      let(:original_pubid) { "NIST NCSTAR 1-1b" }
      let(:short_pubid) { "NIST NCSTAR 1-1B" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST NCSTAR 1-1cv1" do
      let(:original_pubid) { "NIST NCSTAR 1-1cv1" }
      let(:short_pubid) { "NIST NCSTAR 1-1Cv1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST OWMWP 06-13-2018" do
      let(:original_pubid) { "NIST OWMWP 06-13-2018" }
      let(:short_pubid) { "NIST OWMWP 06-13-2018" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NBS CS v6n1" do
      let(:original_pubid) { "NBS CS v6n1" }
      let(:short_pubid) { "NBS CSM v6pt1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "NIST IR 8200-2018" do
      let(:original_pubid) { "NIST IR 8200-2018" }
      let(:short_pubid) { "NIST IR 8200e2018" }
      let(:short_pubid_without_edition) { "NIST IR 8200" }

      it_behaves_like "converts pubid to different formats"
      it_behaves_like "converts pubid to short pubid without edition"
    end

    context "NIST SP 800-121r2/Upd1" do
      let(:short_pubid) { "NIST SP 800-121r2/Upd1" }
      let(:mr_pubid) { "NIST.SP.800-121r2.u1" }

      it_behaves_like "converts pubid to different formats"
    end

    context "when cannot parse code" do
      it "should raise error" do
        expect { described_class.parse("NIST SP WRONG-CODE") }
          .to raise_error(Pubid::Core::Errors::ParseError)
      end
    end
  end

  describe "parse identifiers from examples files" do
    shared_examples "parse identifiers from file" do
      it "parse identifiers from file" do
        f = open("spec/fixtures/#{examples_file}")
        f.readlines.each do |pub_id|
          next if pub_id.match?("^#")
          expect do
            described_class.parse(pub_id.split("#").first.strip.chomp)
          rescue Exception => failure
            raise Pubid::Nist::Errors::ParseError,
                  "couldn't parse #{pub_id}\n#{failure.message}"
          end.not_to raise_error
        end
      end
    end

    context "parses identifiers from allrecords.txt" do
      let(:examples_file) { "allrecords.txt" }

      it_behaves_like "parse identifiers from file"
    end

    context "parses identifiers from pubs-export.txt" do
      let(:examples_file) { "pubs-export.txt" }

      it_behaves_like "parse identifiers from file"
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
end
