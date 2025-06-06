module Pubid::Iso
  RSpec.describe Identifier do
    subject { described_class.parse(original || pubid) }
    let(:original) { nil }
    let(:french_pubid) { original }
    let(:russian_pubid) { original }
    let(:pubid_with_edition) { original }

    context "ISO 4" do
      let(:pubid) { "ISO 4" }
      let(:urn) { "urn:iso:std:iso:4" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid"
    end

    context "ISO/IEC FDIS 7816-6" do
      let(:pubid) { "ISO/IEC FDIS 7816-6" }
      let(:urn) { "urn:iso:std:iso-iec:7816:-6:stage-draft" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/IEC DIS 7816-6"
    end

    context "ISO/TR 30406:2017" do
      let(:pubid) { "ISO/TR 30406:2017" }
      let(:urn) { "urn:iso:std:iso:tr:30406" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/TR 30406" do
      let(:pubid) { "ISO/TR 30406" }
      let(:urn) { "urn:iso:std:iso:tr:30406" }

      it_behaves_like "converts urn to pubid"
    end

    context "IWA 8:2009" do
      let(:pubid) { "IWA 8:2009" }
      let(:urn) { "urn:iso:std:iso:iwa:8" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "IWA 8" do
      let(:pubid) { "IWA 8" }
      let(:urn) { "urn:iso:std:iso:iwa:8" }

      it_behaves_like "converts urn to pubid"
    end

    context "ISO/IEC TR 24754-2:2011" do
      let(:pubid) { "ISO/IEC TR 24754-2:2011" }
      let(:urn) { "urn:iso:std:iso-iec:tr:24754:-2" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC TR 24754-2" do
      let(:pubid) { "ISO/IEC TR 24754-2" }
      let(:urn) { "urn:iso:std:iso-iec:tr:24754:-2" }

      it_behaves_like "converts urn to pubid"
    end

    context "FprISO 105-A03" do
      let(:original) { "FprISO 105-A03" }
      let(:pubid) { "ISO/PRF 105-A03" }
      let(:urn) { "urn:iso:std:iso:105:-A03:stage-draft" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid with prf"
      it_behaves_like "converts urn to pubid", "ISO/DIS 105-A03"
    end

    context "ISO/IEC/IEEE 26512" do
      let(:pubid) { "ISO/IEC/IEEE 26512" }
      let(:urn) { "urn:iso:std:iso-iec-ieee:26512" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid"
    end

    context "ISO/IEC 30142 ED1" do
      let(:original) { "ISO/IEC 30142 ED1" }
      let(:pubid) { "ISO/IEC 30142" }
      let(:urn) { "urn:iso:std:iso-iec:30142:ed-1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts to pubid with edition"
      it_behaves_like "converts urn to pubid"
    end

    context "ISO 22610:2006 Ed" do
      let(:original) { "ISO 22610:2006 Ed" }
      let(:pubid) { "ISO 22610:2006" }
      let(:pubid_with_edition) { "ISO 22610:2006 ED1" }
      let(:urn) { "urn:iso:std:iso:22610:ed-1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts to pubid with edition"
    end

    context "ISO 17121:2000 Ed 1" do
      let(:original) { "ISO 17121:2000 Ed 1" }
      let(:pubid) { "ISO 17121:2000" }
      let(:pubid_with_edition) { "ISO 17121:2000 ED1" }
      let(:urn) { "urn:iso:std:iso:17121:ed-1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts to pubid with edition"
    end

    context "ISO 11553-1 Ed.2" do
      let(:original) { "ISO 11553-1 Ed.2" }
      let(:pubid) { "ISO 11553-1" }
      let(:pubid_with_edition) { "ISO 11553-1 ED2" }
      let(:urn) { "urn:iso:std:iso:11553:-1:ed-2" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts to pubid with edition"
    end

    context "ISO/DIS 21143.2" do
      let(:pubid) { "ISO/DIS 21143.2" }
      let(:urn) { "urn:iso:std:iso:21143:stage-draft.v2" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/DIS 21143.2"
    end

    context "ISO/FDIS 21420.2" do
      let(:pubid) { "ISO/FDIS 21420.2" }
      let(:urn) { "urn:iso:std:iso:21420:stage-draft.v2" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/TR 30406:2017" do
      let(:pubid) { "ISO/TR 30406:2017" }
      let(:urn) { "urn:iso:std:iso:tr:30406" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/TR 30406-2017" do
      let(:pubid) { "ISO/TR 30406:2017" }
      let(:urn) { "urn:iso:std:iso:tr:30406" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO 5843/6" do
      let(:original) { "ISO 5843/6" }
      let(:pubid) { "ISO 5843-6" }
      let(:urn) { "urn:iso:std:iso:5843:-6" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/NP 23219" do
      let(:pubid) { "ISO/NP 23219" }
      let(:urn) { "urn:iso:std:iso:23219:stage-draft" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/NWIP 19144-4" do
      let(:pubid) { "ISO/NP 19144-4" }
      let(:urn) { "urn:iso:std:iso:19144:-4:stage-draft" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "IEC 80601-2-60" do
      let(:pubid) { "IEC 80601-2-60" }
      let(:urn) { "urn:iso:std:iec:80601:-2-60" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid"
    end

    context "ISO/TR27957:2008" do
      let(:original) { "ISO/TR27957:2008" }
      let(:pubid) { "ISO/TR 27957:2008" }
      let(:urn) { "urn:iso:std:iso:tr:27957" }

      it "returns self as root" do
        expect(subject.root).to eq(subject)
      end

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO 10231:2003/Amd 1:2015" do
      let(:pubid) { "ISO 10231:2003/Amd 1:2015" }
      let(:urn) { "urn:iso:std:iso:10231:amd:2015:v1" }

      it "should raise an error when converting to URN" do
        expect { subject.urn }.to raise_exception(Errors::NoEditionError)
      end

      it "shoud have type :amd" do
        expect(subject.type[:key]).to eq(:amd)
      end

      it "returns base identifier as root" do
        expect(subject.root).to eq(subject.base)
      end

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO 10360-1:2000/Cor 1:2002" do
      let(:original) { "ISO 10360-1:2000/Cor 1:2002 ED1" }
      let(:pubid) { "ISO 10360-1:2000/Cor 1:2002" }
      let(:urn) { "urn:iso:std:iso:10360:-1:ed-1:cor:2002:v1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO 10360-1/Cor 1:2002" do
      let(:pubid) { "ISO 10360-1/Cor 1:2002" }
      let(:urn) { "urn:iso:std:iso:10360:-1:cor:2002:v1" }

      it_behaves_like "converts urn to pubid"
    end

    context "ISO 13688:2013/Amd 1:2021(en)" do
      let(:original) { "ISO 13688:2013/Amd 1:2021 ED1(en)" }
      let(:pubid) { "ISO 13688:2013/Amd 1:2021(en)" }
      let(:urn) { "urn:iso:std:iso:13688:ed-1:amd:2021:v1:en" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO 13688/Amd 1:2021(en)" do
      let(:pubid) { "ISO 13688 ED1/Amd 1:2021(en)" }
      let(:urn) { "urn:iso:std:iso:13688:ed-1:amd:2021:v1:en" }

      it_behaves_like "converts urn to pubid"
    end

    context "ISO/IEC 10646:2020/CD Amd 1" do
      let(:original) { "ISO/IEC 10646:2020/CD Amd 1 ED6" }
      let(:pubid) { "ISO/IEC 10646:2020/CD Amd 1" }
      let(:urn) { "urn:iso:std:iso-iec:10646:ed-6:stage-draft:amd:1:v1" }

      # TODO: raise an error when convert CD stage to URN?
      # let(:urn) { "urn:iso:std:iso-iec:10646:ed-6:stage-30.00:amd:1:v1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/IEC 10646 ED6/WD Amd 1"
    end

    context "ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017" do
      let(:original) { "ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017 ED5" }
      let(:pubid) { "ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017" }
      let(:urn) { "urn:iso:std:iso-iec:13818:-1:ed-5:amd:2016:v3:cor:2017:v1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/IEC 13818-1 ED5/Amd 3:2016/Cor 1:2017"

      it "should have type :cor" do
        expect(subject.type[:key]).to eq(:cor)
      end

      it "should have amendment as base identifier" do
        expect(subject.base.type[:key]).to eq(:amd)
      end

      it "should have base document for amendment" do
        expect(subject.base.base).to be_a(Identifier::InternationalStandard)
      end

      it "returns root identifer" do
        expect(subject.root).to eq(subject.base.base)
      end
    end

    context "ISO/IEC 14496-30:2018/FDAmd 1" do
      let(:original) { "ISO/IEC 14496-30:2018/FDAmd 1 ED2" }
      let(:pubid) { "ISO/IEC 14496-30:2018/FDAM 1" }
      let(:urn) { "urn:iso:std:iso-iec:14496:-30:ed-2:stage-draft:amd:1:v1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/IEC 14496-30 ED2/WD Amd 1"
    end

    context "ISO 11783-2:2012/Cor.1:2012(fr)" do
      let(:original) { "ISO 11783-2:2012/Cor.1:2012 ED2(fr)" }
      let(:pubid) { "ISO 11783-2:2012/Cor 1:2012(fr)" }
      let(:urn) { "urn:iso:std:iso:11783:-2:ed-2:cor:2012:v1:fr" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO 11783-2 ED2/Cor 1:2012(fr)"
    end

    context "ISO/IEC 8802-3:2021/Amd7-2021" do
      let(:original) { "ISO/IEC 8802-3:2021/Amd 7:2021 ED3" }
      let(:pubid) { "ISO/IEC 8802-3:2021/Amd 7:2021" }
      let(:urn) { "urn:iso:std:iso-iec:8802:-3:ed-3:amd:2021:v7" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/IEC 8802-3 ED3/Amd 7:2021"
    end

    context "ISO 14451-1:2013(en,fr,other)" do
      let(:pubid) { "ISO 14451-1:2013(en,fr,other)" }
      let(:urn) { "urn:iso:std:iso:14451:-1:en,fr,other" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO 14451-1(en,fr,other)"
    end

    context "ISO 17225-1:2014(R)" do
      let(:original) { "ISO 17225-1:2014(R)" }
      let(:pubid) { "ISO 17225-1:2014(ru)" }
      let(:urn) { "urn:iso:std:iso:17225:-1:ru" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO 17225-1(ru)"
    end

    context "ISO/IEC GUIDE 2:2004(E/F/R)" do
      let(:original) { "ISO/IEC GUIDE 2:2004(E/F/R)" }
      let(:pubid) { "ISO/IEC Guide 2:2004(en,fr,ru)" }
      let(:urn) { "urn:iso:std:iso-iec:guide:2:en,fr,ru" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/IEC Guide 2(en,fr,ru)"
    end

    context "ISO 10791-6:2014/PWI Amd 1" do
      let(:original) { "ISO 10791-6:2014/PWI Amd 1 ED1" }
      let(:pubid) { "ISO 10791-6:2014/PWI Amd 1" }
      let(:urn) { "urn:iso:std:iso:10791:-6:ed-1:stage-draft:amd:1:v1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO 10791-6 ED1/WD Amd 1"
    end

    context "ISO 11137-2:2013/FDAmd 1" do
      let(:original) { "ISO 11137-2:2013/FDAmd 1 ED3" }
      let(:pubid) { "ISO 11137-2:2013/FDAM 1" }
      let(:urn) { "urn:iso:std:iso:11137:-2:ed-3:stage-draft:amd:1:v1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO 11137-2 ED3/WD Amd 1"
    end

    context "ISO 15002:2008/DAM 2:2020(F)" do
      let(:original) { "ISO 15002:2008/DAM 2:2020 ED2(F)" }
      let(:pubid) { "ISO 15002:2008/DAM 2:2020(fr)" }
      # let(:urn) { "urn:iso:std:iso:15002:ed-2:stage-40.00:amd:2020:v2:fr" }

      # it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
    end

    context "ISO 15002:2008/DAM 2:2020(F)" do
      let(:original) { "ISO 15002:2008/DAM 2:2020 ED2(F)" }
      let(:urn) { "urn:iso:std:iso:15002:ed-2:stage-draft:amd:2020:v2:fr" }

      it_behaves_like "converts urn to pubid", "ISO 15002 ED2/WD Amd 2:2020(fr)"
    end

    context "ISO/IEC 10646-1:1993/pDCOR.2" do
      let(:original) { "ISO/IEC 10646-1:1993/pDCOR.2 ED1" }
      let(:pubid) { "ISO/IEC 10646-1:1993/CD Cor 2" }
      let(:urn) { "urn:iso:std:iso-iec:10646:-1:ed-1:stage-draft:cor:2:v1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/IEC 10646-1 ED1/WD Cor 2"
    end

    context "ISO/IEC 14496-12:2012/PDAM 4" do
      let(:original) { "ISO/IEC 14496-12:2012/PDAM 4 ED4" }
      let(:pubid) { "ISO/IEC 14496-12:2012/CD Amd 4" }
      let(:urn) { "urn:iso:std:iso-iec:14496:-12:ed-4:stage-draft:amd:4:v1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/IEC 14496-12 ED4/WD Amd 4"
    end

    context "ISO/IEC PDTR 20943-5" do
      let(:original) { "ISO/IEC PDTR 20943-5" }
      let(:pubid) { "ISO/IEC CD TR 20943-5" }
      let(:urn) { "urn:iso:std:iso-iec:tr:20943:-5:stage-draft" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/IEC DTR 20943-5"
    end

    context "ISO/IEC PDTS 19583-24" do
      let(:original) { "ISO/IEC PDTS 19583-24" }
      let(:pubid) { "ISO/IEC CD TS 19583-24" }
      let(:urn) { "urn:iso:std:iso-iec:ts:19583:-24:stage-draft" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/IEC DTS 19583-24"
    end

    context "GUIDE ISO/CEI 71:2001(F)" do
      let(:original) { "GUIDE ISO/CEI 71:2001(F)" }
      let(:pubid) { "ISO/IEC Guide 71:2001(fr)" }
      let(:french_pubid) { "Guide ISO/CEI 71:2001(fr)" }
      let(:urn) { "urn:iso:std:iso-iec:guide:71:fr" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to french pubid"
      it_behaves_like "converts urn to pubid", "ISO/IEC Guide 71(fr)"
    end

    context "ISO 6709:2008/Cor. 1:2009" do
      let(:original) { "ISO 6709:2008/Cor. 1:2009 ED2" }
      let(:pubid) { "ISO 6709:2008/Cor 1:2009" }
      let(:urn) { "urn:iso:std:iso:6709:ed-2:cor:2009:v1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO 6709 ED2/Cor 1:2009"
    end

    context "ISO 10993-4:2002/Amd. 1:2006(E)" do
      let(:original) { "ISO 10993-4:2002/Amd.1:2006 ED2(E)" }
      let(:pubid) { "ISO 10993-4:2002/Amd 1:2006(en)" }
      let(:urn) { "urn:iso:std:iso:10993:-4:ed-2:amd:2006:v1:en" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO 10993-4 ED2/Amd 1:2006(en)"

      it "returns part without dash" do
        expect(subject.base.part).to eq("4")
      end
    end

    context "ISO/IEC 17025:2005/Cor.1:2006(fr)" do
      let(:original) { "ISO/IEC 17025:2005/Cor.1:2006 ED1(fr)" }
      let(:pubid) { "ISO/IEC 17025:2005/Cor 1:2006(fr)" }
      let(:pubid_without_date) { "ISO/IEC 17025:2005/Cor 1" }
      let(:pubid_single_letter_language) { "ISO/IEC 17025:2005/Cor 1:2006(F)" }
      let(:pubid_with_edition) { "ISO/IEC 17025:2005 ED1/Cor 1:2006(fr)" }
      let(:french_pubid) { "ISO/CEI 17025:2005/Cor.1:2006(fr)" }
      let(:urn) { "urn:iso:std:iso-iec:17025:ed-1:cor:2006:v1:fr" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to french pubid"
      it_behaves_like "converts urn to pubid", "ISO/IEC 17025 ED1/Cor 1:2006(fr)"

      it "converts to pubid without date" do
        expect(subject.to_s(format: :ref_undated_long)).to eq(pubid_without_date)
      end

      it "converts to pubid with single letter language code" do
        expect(subject.to_s(format: :ref_num_short)).to eq(pubid_single_letter_language)
      end

      it_behaves_like "converts to pubid with edition"
    end

    context "ISO 5537|IDF 26" do
      let(:original) { "ISO 5537|IDF 26" }
      let(:pubid) { "ISO 5537|IDF 26" }
      let(:urn) { "urn:iso:std:iso:5537" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO 5537"
    end

    context "Руководство ИСО/МЭК 76" do
      let(:original) { "Руководство ИСО/МЭК 76" }
      let(:pubid) { "ISO/IEC Guide 76" }
      let(:urn) { "urn:iso:std:iso-iec:guide:76" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to russian pubid"
      it_behaves_like "converts urn to pubid", "ISO/IEC Guide 76"
    end

    context "ИСО/ОПМС 26000:2010(R)" do
      let(:original) { "ИСО/ОПМС 26000:2010(R)" }
      let(:pubid) { "ISO/FDIS 26000:2010(ru)" }
      let(:russian_pubid) { "ИСО/ОПМС 26000:2010(ru)" }
      let(:urn) { "urn:iso:std:iso:26000:stage-draft:ru" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to russian pubid"
      it_behaves_like "converts urn to pubid", "ISO/DIS 26000(ru)"
    end

    context "ИСО/ПМС 1956/2" do
      let(:original) { "ИСО/ПМС 1956/2" }
      let(:pubid) { "ISO/DIS 1956-2" }
      let(:urn) { "urn:iso:std:iso:1956:-2:stage-draft" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/DIS 1956-2"
    end

    context "ИСО/ТС 18625" do
      let(:original) { "ИСО/ТС 18625" }
      let(:pubid) { "ISO/TS 18625" }
      let(:urn) { "urn:iso:std:iso:ts:18625" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/TS 18625"
    end

    context "ИСО/ТО 8517" do
      let(:original) { "ИСО/ТО 8517" }
      let(:pubid) { "ISO/TR 8517" }
      let(:urn) { "urn:iso:std:iso:tr:8517" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/TR 8517"
    end

    context "ИСО/ТС 18625" do
      let(:original) { "ИСО/ТС 18625" }
      let(:pubid) { "ISO/TS 18625" }
      let(:urn) { "urn:iso:std:iso:ts:18625" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/TS 18625"
    end

    context "AWI IWA 36" do
      let(:original) { "AWI IWA 36" }
      let(:pubid) { "AWI IWA 36" }
      let(:urn) { "urn:iso:std:iso:iwa:36:stage-draft" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "DIWA 36"
    end

    context "ISO/IEC WD TS 25025" do
      let(:original) { "ISO/IEC WD TS 25025" }
      let(:pubid) { "ISO/IEC WD TS 25025" }
      let(:urn) { "urn:iso:std:iso-iec:ts:25025:stage-draft" }

      it "return typed_stage_abbrev" do
        expect(subject.typed_stage_abbrev).to eq("WD TS")
      end

      it "return typed_stage_name" do
        expect(subject.typed_stage_name).to eq("Working Draft Technical Specification")
      end

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO/IEC DTS 25025"
    end

    context "ISO 19110:2005/Amd 1:2011" do
      let(:original) { "ISO 19110:2005/Amd 1:2011 ED1" }
      let(:pubid) { "ISO 19110:2005/Amd 1:2011" }
      let(:urn) { "urn:iso:std:iso:19110:ed-1:amd:2011:v1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts urn to pubid", "ISO 19110 ED1/Amd 1:2011"
    end

    context "ISO 17301-1:2016/NP Amd 1.2" do
      let(:pubid) { "ISO 17301-1:2016/NP Amd 1.2" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO 17301-1:2016/NP Amd 1.2" do
      let(:pubid) { "ISO 17301-1:2016 ED1/NP Amd 1.2" }
      let(:urn) { "urn:iso:std:iso:17301:-1:ed-1:stage-draft:amd:1:v1" }

      it_behaves_like "converts urn to pubid", "ISO 17301-1 ED1/WD Amd 1"
    end

    # Confirms there is no short typed-stage abbreviation for Amd at WD stages
    context "ISO/IEC FDIS 23008-1/WD Amd 1" do
      let(:pubid) { "ISO/IEC FDIS 23008-1/WD Amd 1" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC FDIS 23008-1/WD Amd 1" do
      let(:pubid) { "ISO/IEC FDIS 23008-1/WD Amd 1" }
      let(:urn) { "urn:iso:std:iso-iec:23008:-1:stage-draft:ed-2:stage-draft:amd:1:v1" }

      it_behaves_like "converts urn to pubid", "ISO/IEC DIS 23008-1 ED2/WD Amd 1"
    end

    # Confirms usage of short typed-stage abbreviation for Amd at DIS stages
    context "ISO/IEC FDIS 23090-14/DAmd 1" do
      let(:original) { "ISO/IEC FDIS 23090-14/DAmd 1" }
      let(:pubid) { "ISO/IEC FDIS 23090-14/DAM 1" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO 17301-1:2016/FCOR 2.3" do
      let(:original) { "ISO 17301-1:2016/FCOR 2.3" }
      let(:pubid) { "ISO 17301-1:2016/FDCOR 2.3" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC/IEEE DTS 17301-1-1:2016(en)" do
      let(:pubid) { "ISO/IEC/IEEE DTS 17301-1-1:2016(en)" }
      let(:urn) { "urn:iso:std:iso-iec-ieee:ts:17301:-1-1:stage-draft:en" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/IEC/IEEE DTS 17301-1-1(en)"

      it "returns part with dash" do
        expect(subject.part).to eq("1-1")
      end
    end

    context "ISO/IEC/IEEE FDTR 17301-1-1:2016(en)" do
      let(:pubid) { "ISO/IEC/IEEE FDTR 17301-1-1:2016(en)" }
      let(:urn) { "urn:iso:std:iso-iec-ieee:tr:17301:-1-1:stage-draft:en" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/IEC/IEEE DTR 17301-1-1(en)"

      it "return typed_stage_abbrev" do
        expect(subject.typed_stage_abbrev).to eq("FDTR")
      end

      it "return typed_stage_name" do
        expect(subject.typed_stage_name).to eq("Final Draft Technical Report")
      end
    end

    context "ISO/IEC 14496-10:2014/FPDAM 1(en)" do
      let(:original) { "ISO/IEC 14496-10:2014/FPDAM 1(en)" }
      let(:pubid) { "ISO/IEC 14496-10:2014/DAM 1(en)" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC 14496-10 ED1/FPDAM 1(en)" do
      let(:urn) { "urn:iso:std:iso-iec:14496:-10:ed-1:stage-draft:amd:1:v1:en" }

      it_behaves_like "converts urn to pubid", "ISO/IEC 14496-10 ED1/WD Amd 1(en)"
    end

    context "ISO/IEC 27006:2015/PDAM 1" do
      let(:original) { "ISO/IEC 27006:2015/PDAM 1" }
      let(:pubid) { "ISO/IEC 27006:2015/CD Amd 1" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/PRF 6709:2022" do
      let(:original) { "ISO/PRF 6709:2022" }
      let(:pubid) { "ISO/PRF 6709:2022" }
      let(:pubid_with_prf) { original }

      it "return typed_stage_abbrev" do
        expect(subject.typed_stage_abbrev).to eq("PRF")
      end

      it "return typed_stage_name" do
        expect(subject.typed_stage_name).to eq("Proof of a new International Standard")
      end

      it_behaves_like "converts pubid to pubid with prf"
    end

    context "ISO/CD PAS 22399" do
      let(:original) { "ISO/CD PAS 22399" }
      let(:pubid) { "ISO/CD PAS 22399" }
      let(:urn) { "urn:iso:std:iso:pas:22399:stage-draft" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/DPAS 22399"
    end

    context "ISO/DPAS 5643:2021(E)" do
      let(:original) { "ISO/DPAS 5643:2021(E)" }
      let(:pubid) { "ISO/DPAS 5643:2021(en)" }
      let(:urn) { "urn:iso:std:iso:pas:5643:stage-draft:en"}

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/DPAS 5643(en)"
    end

    context "ISO/PRF PAS 5643" do
      let(:pubid) { "ISO/PRF PAS 5643" }
      let(:urn) { "urn:iso:std:iso:pas:5643:stage-draft"}

      it "return typed_stage_abbrev" do
        expect(subject.typed_stage_abbrev).to eq("PRF PAS")
      end

      it "return typed_stage_name" do
        expect(subject.typed_stage_name).to eq("Proof of a new Publicly Available Specification")
      end

      it_behaves_like "converts pubid to pubid with prf"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/DPAS 5643"
    end

    context "ISO/SAE DPAS 22736:2021" do
      let(:pubid) { "ISO/SAE DPAS 22736:2021" }
      let(:urn) { "urn:iso:std:iso-sae:pas:22736:stage-draft" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/SAE DPAS 22736"
    end

    context "ISO/IEC FDIS 23008-1/WD Amd 1" do
      let(:pubid) { "ISO/IEC FDIS 23008-1/WD Amd 1" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO 19115:2003(en,fr)" do
      let(:pubid) { "ISO 19115:2003(en,fr)" }
      let(:urn) { "urn:iso:std:iso:19115:en,fr" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO 19115(en,fr)"

      it "has assigned IS type" do
        expect(subject.type[:key]).to eq(:is)
      end
    end

    context "ISO/TS 19115-3:2016" do
      let(:pubid) { "ISO/TS 19115-3:2016" }
      let(:urn) { "urn:iso:std:iso:ts:19115:-3" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/TS 19115-3"
    end

    context "ISO/IEEE 11073-20601:2010" do
      let(:pubid) { "ISO/IEEE 11073-20601:2010" }
      let(:urn) { "urn:iso:std:iso-ieee:11073:-20601" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/IEEE 11073-20601"
    end

    context "ISO 105-C06:2010" do
      let(:pubid) { "ISO 105-C06:2010" }
      let(:urn) { "urn:iso:std:iso:105:-C06" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO 105-C06"
    end

    context "ISO/R 125:1966" do
      let(:pubid) { "ISO/R 125:1966" }
      let(:urn) { "urn:iso:std:iso:r:125" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/R 125"
    end

    context "ISO/R 93-3:1969" do
      let(:pubid) { "ISO/R 93-3:1969" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/R 93/1-1963" do
      let(:original) { "ISO/R 93/1-1963" }
      let(:pubid) { "ISO/R 93-1:1963" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/R 300/III-1968" do
      let(:original) { "ISO/R 300/III-1968" }
      let(:pubid) { "ISO/R 300-3:1968" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/R 657/IV" do
      let(:original) { "ISO/R 657/IV" }
      let(:pubid) { "ISO/R 657-4:1969" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/R 947:1969/Add 1:1969" do
      let(:pubid) { "ISO/R 947:1969/Add 1:1969" }
      let(:urn) { "urn:iso:std:iso:r:947:sup:1969:v1" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/R 947/Suppl 1:1969"
    end

    context "ISO/R 194:1969/Add 4" do
      let(:pubid) { "ISO/R 194:1969/Add 4" }
      let(:urn) { "urn:iso:std:iso:r:194:sup:4:v1" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/R 194/Suppl 4"
    end

    context "ISO/R 91-1970 — Addendum 1" do
      let(:original) { "ISO/R 91-1970 — Addendum 1" }
      let(:pubid) { "ISO/R 91:1970/Add 1" }
      let(:urn) { "urn:iso:std:iso:r:91:sup:1:v1" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/R 91/Suppl 1"
    end

    context "ISO/R 91:1970/ADD 1:1975" do
      let(:original) { "ISO/R 91:1970/ADD 1:1975" }
      let(:pubid) { "ISO/R 91:1970/Add 1:1975" }
      let(:urn) { "urn:iso:std:iso:r:91:sup:1975:v1" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/R 91/Suppl 1:1975"
    end

    context "ISO 1942:1983/Add 1:1983" do
      let(:pubid) { "ISO 1942:1983/Add 1:1983" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/TR 8373:1988/Add 1:1990" do
      let(:pubid) { "ISO/TR 8373:1988/Add 1:1990" }
      let(:urn) { "urn:iso:std:iso:tr:8373:sup:1990:v1" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/TR 8373/Suppl 1:1990"
    end

    context "ISO/IEC ISP 10611-3:2003" do
      let(:pubid) { "ISO/IEC ISP 10611-3:2003" }
      let(:urn) { "urn:iso:std:iso-iec:isp:10611:-3" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/IEC ISP 10611-3"
    end

    context "ISO DGUIDE 84" do
      let(:original) { "ISO DGUIDE 84" }
      let(:pubid) { "ISO/DGuide 84" }
      let(:urn) { "urn:iso:std:iso:guide:84:stage-draft" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/DGuide 84"
    end

    context "ISO/AWI Guide 30" do
      let(:pubid) { "ISO/AWI Guide 30" }
      let(:urn) { "urn:iso:std:iso:guide:30:stage-draft" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/DGuide 30"
    end

    context "ISO/DGuide 31(en)" do
      let(:pubid) { "ISO/DGuide 31(en)" }
      let(:urn) { "urn:iso:std:iso:guide:31:stage-draft:en" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid"
    end

    context "ISO/IEC FD GUIDE 98-1" do
      let(:original) { "ISO/IEC FD GUIDE 98-1" }
      let(:pubid) { "ISO/IEC FDGuide 98-1" }
      let(:urn) { "urn:iso:std:iso-iec:guide:98:-1:stage-draft" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/IEC DGuide 98-1"
    end

    context "ISO/IEC FD Guide 98-1" do
      let(:original) { "ISO/IEC FD Guide 98-1" }
      let(:pubid) { "ISO/IEC FDGuide 98-1" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/TTA 5:2007" do
      let(:pubid) { "ISO/TTA 5:2007" }
      let(:urn) { "urn:iso:std:iso:tta:5" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/TTA 5"
    end

    context "ISO/IWA 32:2019(en)" do
      let(:original) { "ISO/IWA 32:2019(en)" }
      let(:pubid) { "IWA 32:2019(en)" }
      let(:urn) { "urn:iso:std:iso:iwa:32:en" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "IWA 32(en)"
    end

    context "ISO Guide 98:1995/DSuppl 1.2" do
      let(:pubid) { "ISO Guide 98:1995/DSuppl 1.2" }
      let(:urn) { "urn:iso:std:iso:guide:98:stage-draft:sup:1:v1" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/DGuide 98/Suppl 1"
    end

    context "IWA 32:2019(en)" do
      let(:pubid) { "IWA 32:2019(en)" }
      let(:urn) { "urn:iso:std:iso:iwa:32:en" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "IWA 32(en)"
    end

    context "ISO/IEC Guide 98-3/NP Suppl 2" do
      let(:pubid) { "ISO/IEC Guide 98-3/NP Suppl 2" }
      let(:urn) { "urn:iso:std:iso-iec:guide:98:-3:stage-draft:sup:2:v1" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/IEC DGuide 98-3/Suppl 2"
    end

    context "CD IWA 37-3" do
      let(:pubid) { "CD IWA 37-3" }
      let(:urn) { "urn:iso:std:iso:iwa:37:-3:stage-draft" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "DIWA 37-3"
    end

    context "ISO/IEC Guide 98-3/Suppl.1:2008" do
      let(:original) { "ISO/IEC Guide 98-3/Suppl.1:2008" }
      let(:pubid) { "ISO/IEC Guide 98-3/Suppl 1:2008" }
      let(:urn) { "urn:iso:std:iso-iec:guide:98:-3:sup:2008:v1" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/IEC Guide 98-3/Suppl 1:2008"
    end

    context "ISO/WD IWA 19" do
      let(:original) { "ISO/WD IWA 19" }
      let(:pubid) { "WD IWA 19" }
      let(:urn) { "urn:iso:std:iso:iwa:19:stage-draft" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "DIWA 19"
    end

    context "ISO/IEC Guide 98-3:2008/Suppl 1:2008/Cor 1:2009" do
      let(:pubid) { "ISO/IEC Guide 98-3:2008/Suppl 1:2008/Cor 1:2009" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC Guide 98-3 ED1/Suppl 1:2008/Cor 1:2009" do
      let(:pubid) { "ISO/IEC Guide 98-3 ED1/Suppl 1:2008/Cor 1:2009" }
      let(:urn) { "urn:iso:std:iso-iec:guide:98:-3:ed-1:sup:2008:v1:cor:2009:v1" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid"
    end

    context "PRF IWA 36" do
      let(:pubid) { "PRF IWA 36" }
      let(:urn) { "urn:iso:std:iso:iwa:36:stage-draft" }

      it "return typed_stage_abbrev" do
        expect(subject.typed_stage_abbrev).to eq("PRF IWA")
      end

      it "return typed_stage_name" do
        expect(subject.typed_stage_name).to eq("Proof of a new International Workshop Agreement")
      end


      it_behaves_like "converts pubid to pubid with prf"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "DIWA 36"
    end

    context "ISO/IEC Guide 98-3:2008/Suppl.1:2008(en)" do
      let(:original) { "ISO/IEC Guide 98-3:2008/Suppl.1:2008(en)" }
      let(:pubid) { "ISO/IEC Guide 98-3:2008/Suppl 1:2008(en)" }
      let(:urn) { "urn:iso:std:iso-iec:guide:98:-3:sup:2008:v1:en" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/IEC Guide 98-3/Suppl 1:2008(en)"
    end

    context "ISO/IEC NP Guide 98:1995/DSuppl 1.2" do
      let(:pubid) { "ISO/IEC NP Guide 98:1995/DSuppl 1.2" }
      let(:urn) { "urn:iso:std:iso-iec:guide:98:stage-draft:stage-draft:sup:1:v1" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/IEC DGuide 98/DSuppl 1"
    end

    context "ISO 3758:1991/Suppl:1993" do
      let(:pubid) { "ISO 3758:1991/Suppl:1993" }
      let(:urn) { "urn:iso:std:iso:3758:sup:1993" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO 3758/Suppl:1993"
    end

    context "ISO/PRF TR 23249" do
      let(:pubid) { "ISO/PRF TR 23249" }
      let(:urn) { "urn:iso:std:iso:tr:23249:stage-draft" }

      it "return typed_stage_abbrev" do
        expect(subject.typed_stage_abbrev).to eq("PRF TR")
      end

      it "return typed_stage_name" do
        expect(subject.typed_stage_name).to eq("Proof of a new Technical Report")
      end

      it_behaves_like "converts pubid to pubid with prf"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/DTR 23249"
    end

    context "ISO/IEC 23008-1/WD Amd 1" do
      let(:pubid) { "ISO/IEC 23008-1/WD Amd 1" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC/IEEE 8802-22.2:2015/Amd.2:2017(E)" do
      let(:original) { "ISO/IEC/IEEE 8802-22.2:2015/Amd.2:2017(E)" }
      let(:pubid) { "ISO/IEC/IEEE 8802-22:2015/Amd 2:2017(en)" }

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/IEC/IEEE 8802-22:2015 ED1/Amd 2:2017(en)" do
      let(:pubid) { "ISO/IEC/IEEE 8802-22:2015 ED1/Amd 2:2017(en)" }
      let(:urn) { "urn:iso:std:iso-iec-ieee:8802:-22:ed-1:amd:2017:v2:en" }

      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/IEC/IEEE 8802-22 ED1/Amd 2:2017(en)"
    end

    context "ISO/CD2 14065:2018" do
      let(:original) { "ISO/CD2 14065:2018" }
      let(:pubid) { "ISO/CD 14065.2:2018" }
      let(:urn) { "urn:iso:std:iso:14065:stage-draft.v2" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/DIS 14065.2"
    end

    context "ISO 1101:1983/Ext 1:1983" do
      let(:pubid) { "ISO 1101:1983/Ext 1:1983" }
      let(:urn) { "urn:iso:std:iso:1101:ext:1983:v1" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO 1101/Ext 1:1983"
    end

    context "ISO/CD 105-C12" do
      let(:pubid) { "ISO/CD 105-C12" }
      let(:urn) { "urn:iso:std:iso:105:-C12:stage-draft" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/DIS 105-C12"
    end

    context "ISO/IEC CD 29110-5-1-1" do
      let(:pubid) { "ISO/IEC CD 29110-5-1-1" }
      let(:urn) { "urn:iso:std:iso-iec:29110:-5-1-1:stage-draft" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/IEC DIS 29110-5-1-1"
    end

    context "ISO/PRF TR 31700-2" do
      let(:pubid) { "ISO/PRF TR 31700-2" }
      let(:urn) { "urn:iso:std:iso:tr:31700:-2:stage-draft" }

      it_behaves_like "converts pubid to pubid with prf"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/DTR 31700-2"
    end

    context "IEC/DPAS 63086-3-1" do
      let(:pubid) { "IEC/DPAS 63086-3-1" }
      let(:urn) { "urn:iso:std:iec:pas:63086:-3-1:stage-draft" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "IEC/DPAS 63086-3-1"
    end

    context "IWA 42:2022" do
      let(:pubid) { "IWA 42:2022" }
      let(:urn) { "urn:iso:std:iso:iwa:42" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "IWA 42"
    end

    context "ISO/IEEE 11073-20601:2022" do
      let(:pubid) { "ISO/IEEE 11073-20601:2022" }
      let(:urn) { "urn:iso:std:iso-ieee:11073:-20601" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/IEEE 11073-20601"
    end

    context "Unicode hyphen" do
      context "U+2010" do
        let(:original) { "ISO/IEC 80079‑34:2020" }
        let(:pubid) { "ISO/IEC 80079-34:2020" }

        it_behaves_like "converts pubid to pubid"
      end

      context "U+2011" do
        let(:original) { "ISO/IEC 80079‐34:2020" }
        let(:pubid) { "ISO/IEC 80079-34:2020" }

        it_behaves_like "converts pubid to pubid"
      end
    end

    context "Draft Addenda" do
      context "ISO 2631/DAD 1" do
        let(:pubid) { "ISO 2631/DAD 1" }
        let(:urn) { "urn:iso:std:iso:2631:stage-draft:sup:1:v1" }

        it_behaves_like "converts pubid to pubid"
        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts urn to pubid", "ISO/DIS 2631/Suppl 1" # @TODO should be ISO 2631/DAD 1

        it { expect(subject).to be_a(Identifier::Addendum) }
      end

      context "ISO 2553/DAD 1:1987" do
        let(:pubid) { "ISO 2553/DAD 1:1987" }
        let(:urn) { "urn:iso:std:iso:2553:stage-draft:sup:1987:v1" }

        it_behaves_like "converts pubid to pubid"
        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts urn to pubid", "ISO/DIS 2553/Suppl 1:1987" # @TODO should be ISO 2553/DAD 1:1987
      end

      context "ISO/DIS 1151-1/DAD 2" do
        let(:pubid) { "ISO/DIS 1151-1/DAD 2" }
        let(:urn) { "urn:iso:std:iso:1151:-1:stage-draft:stage-draft:sup:2:v1" }

        it_behaves_like "converts pubid to pubid"
        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts urn to pubid", "ISO/DIS 1151-1/DSuppl 2"
      end
    end

    context "ISO/IEC FCD 42010" do
      let(:pubid) { "ISO/IEC FCD 42010" }
      let(:urn) { "urn:iso:std:iso-iec:42010:stage-draft" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/IEC DIS 42010"
    end

    context "ISO/DP 8073" do
      let(:pubid) { "ISO/DP 8073" }
      let(:urn) { "urn:iso:std:iso:8073:stage-draft" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/DIS 8073"
    end

    context "IEEE/ISO/IEC 8802-1Q-2020" do
      let(:original) { "IEEE/ISO/IEC 8802-1Q-2020" }
      let(:pubid) { "IEEE/ISO/IEC 8802-1Q:2020" }
      let(:urn) { "urn:iso:std:ieee-iec-iso:8802:-1Q" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "IEEE/IEC/ISO 8802-1Q"
    end

    context "ISO/DATA 3:1977" do
      let(:pubid) { "ISO/DATA 3:1977" }
      let(:urn) { "urn:iso:std:iso:data:3" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/DATA 3"
    end

    context "ISO 7029:2017/PRF Amd 1" do
      let(:pubid) { "ISO 7029:2017/PRF Amd 1" }

      it_behaves_like "converts pubid to pubid with prf"
    end

    context "ISO/IEC preCD 29135" do
      let(:original) { "ISO/IEC preCD 29135" }
      let(:pubid) { "ISO/IEC PreCD 29135" } # @TODO urn: cannot render fuzzy stages

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/PreCD3 17301-1" do
      let(:original) { "ISO/PreCD3 17301-1" }
      let(:pubid) { "ISO/PreCD 17301-1.3" } # @TODO urn: cannot render fuzzy stages

      it_behaves_like "converts pubid to pubid"
    end

    context "ISO/UNDP PAS 53002" do
      let(:pubid) { "ISO/UNDP PAS 53002" }
      let(:urn) { "urn:iso:std:iso-undp:pas:53002" }

      it_behaves_like "converts pubid to pubid"
      it_behaves_like "converts pubid to urn"
      it_behaves_like "converts urn to pubid", "ISO/UNDP PAS 53002"
    end

    context "URN with numered stage" do
      context "Base" do
        context "60.60" do
          let(:urn) { "urn:iso:std:iec:60086:-3:stage-60.60" }
          it_behaves_like "converts urn to pubid", "IEC/IS 60086-3"
          it_behaves_like "converts urn to urn", "urn:iso:std:iec:60086:-3:stage-published"
        end

        context "95.99" do
          let(:urn) { "urn:iso:std:iec:31010:stage-95.99" }
          it_behaves_like "converts urn to pubid", "IEC/WDAR 31010"
          it_behaves_like "converts urn to urn"
        end
      end

      context "Suppliment" do
        context "60.00" do
          let(:urn) { "urn:iso:std:iso:10033:-1:ed-1:stage-60.00:amd:1:v1"}
          it_behaves_like "converts urn to pubid", "ISO 10033-1 ED1/IS Amd 1"
          it_behaves_like "converts urn to urn", "urn:iso:std:iso:10033:-1:ed-1:stage-published:amd:1:v1"
        end

        context "60.60" do
          let(:urn) { "urn:iso:std:iec:60086:-3:ed-4:stage-60.60:cor:2023:v1" }
          it_behaves_like "converts urn to pubid", "IEC 60086-3 ED4/IS Cor 1:2023"
          it_behaves_like "converts urn to urn", "urn:iso:std:iec:60086:-3:ed-4:stage-published:cor:2023:v1"
        end

        context "90.92" do
          let(:urn) { "urn:iso:std:iso:11930:ed-2:stage-90.92:amd:2022:v1" }
          it_behaves_like "converts urn to pubid", "ISO 11930 ED2/WDR Amd 1:2022"
          it_behaves_like "converts urn to urn"
        end

        context "90.93" do
          let(:urn) { "urn:iso:std:iso:12085:ed-1:stage-90.93:cor:1998:v1" }
          it_behaves_like "converts urn to pubid", "ISO 12085 ED1/WDA Cor 1:1998"
          it_behaves_like "converts urn to urn"
        end

        context "95.99 Cor" do
          let(:urn) { "urn:iso:std:iec:60601:-1-11:ed-1:stage-95.99:cor:2011:v1" }
          it_behaves_like "converts urn to pubid", "IEC 60601-1-11 ED1/WDAR Cor 1:2011"
          it_behaves_like "converts urn to urn"
        end

        context "95.99" do
          let(:urn) { "urn:iso:std:iso:1151:-2:ed-2:stage-95.99:sup:1987:v1" }
          it_behaves_like "converts urn to pubid", "ISO 1151-2 ED2/WDAR Suppl 1:1987"
          it_behaves_like "converts urn to urn"
        end
      end

      context "Extension" do
        context "95.99" do
          let(:urn) { "urn:iso:std:iso:1101:ed-1:stage-95.99:ext:1983:v1" }
          it_behaves_like "converts urn to pubid", "ISO 1101 ED1/Ext 1:1983"
          it_behaves_like "converts urn to urn", "urn:iso:std:iso:1101:ed-1:ext:1983:v1"
        end
      end
    end

    context "all parts" do
      context "Base" do
        let(:pubid) { "ISO/IEC FDIS 7816 (all parts)" }
        let(:urn) { "urn:iso:std:iso-iec:7816:stage-draft:ser" }

        it_behaves_like "converts pubid to pubid"
        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts urn to pubid", "ISO/IEC DIS 7816 (all parts)"
      end

      context "Corrigendum" do
        let(:original) { "ISO/IEC Guide 98 ED1/Suppl 1:2008/Cor 1:2009 (all parts)" }
        let(:pubid) { "ISO/IEC Guide 98/Suppl 1:2008/Cor 1:2009 (all parts)" }
        let(:urn) { "urn:iso:std:iso-iec:guide:98:ed-1:sup:2008:v1:cor:2009:v1:ser" }

        it_behaves_like "converts pubid to pubid"
        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts urn to pubid"
      end

      context "Addendment" do
        let(:original) { "ISO/IEC 14496:2018/FDAmd 1 ED2 (all parts)" }
        let(:pubid) { "ISO/IEC 14496:2018/FDAM 1 (all parts)" }
        let(:urn) { "urn:iso:std:iso-iec:14496:ed-2:stage-draft:amd:1:v1:ser" }

        it_behaves_like "converts pubid to pubid"
        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts urn to pubid", "ISO/IEC 14496 ED2/WD Amd 1 (all parts)"
      end

      context "Supplement" do
        let(:pubid) { "ISO 8501:1988/Suppl:1994 (all parts)" }
        let(:urn) { "urn:iso:std:iso:8501:sup:1994:ser" }

        it_behaves_like "converts pubid to pubid"
        it_behaves_like "converts pubid to urn"
      end
    end

    context "URN stage-published" do
      let(:urn) { "urn:iso:std:iso:19115:-3:stage-published" }
      it_behaves_like "converts urn to pubid", "ISO/IS 19115-3"
    end

    context "iso-reference" do
      # let(:pubid) { "ISO 21622-3.2(E)" }
      # it_behaves_like "converts pubid to pubid"
    end
  end
end
