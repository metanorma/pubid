module Pubid::Iso
  module Identifier
    RSpec.describe Base do
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
      end

      context "ISO/IEC FDIS 7816-6" do
        let(:pubid) { "ISO/IEC FDIS 7816-6" }
        let(:urn) { "urn:iso:std:iso-iec:7816:-6:stage-draft" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/TR 30406:2017" do
        let(:pubid) { "ISO/TR 30406:2017" }
        let(:urn) { "urn:iso:std:iso:tr:30406" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "IWA 8:2009" do
        let(:pubid) { "IWA 8:2009" }
        let(:urn) { "urn:iso:std:iwa:8" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC TR 24754-2:2011" do
        let(:pubid) { "ISO/IEC TR 24754-2:2011" }
        let(:urn) { "urn:iso:std:iso-iec:tr:24754:-2" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "FprISO 105-A03" do
        let(:original) { "FprISO 105-A03" }
        let(:pubid) { "ISO/PRF 105-A03" }
        let(:urn) { "urn:iso:std:iso:105:-A03:stage-60.00" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid with prf"
      end

      context "ISO/IEC/IEEE 26512" do
        let(:pubid) { "ISO/IEC/IEEE 26512" }
        let(:urn) { "urn:iso:std:iso-iec-ieee:26512" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC 30142 ED1" do
        let(:original) { "ISO/IEC 30142 ED1" }
        let(:pubid) { "ISO/IEC 30142" }
        let(:urn) { "urn:iso:std:iso-iec:30142:ed-1" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
        it_behaves_like "converts to pubid with edition"
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
      end

      context "ISO/TR27957:2008" do
        let(:original) { "ISO/TR27957:2008" }
        let(:pubid) { "ISO/TR 27957:2008" }
        let(:urn) { "urn:iso:std:iso:tr:27957" }

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
          expect(subject.type).to eq(:amd)
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

      context "ISO 13688:2013/Amd 1:2021(en)" do
        let(:original) { "ISO 13688:2013/Amd 1:2021 ED1(en)" }
        let(:pubid) { "ISO 13688:2013/Amd 1:2021(en)" }
        let(:urn) { "urn:iso:std:iso:13688:ed-1:amd:2021:v1:en" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC 10646:2020/CD Amd 1" do
        let(:original) { "ISO/IEC 10646:2020/CD Amd 1 ED6" }
        let(:pubid) { "ISO/IEC 10646:2020/CD Amd 1" }

        # TODO: raise an error when convert CD stage to URN?
        # let(:urn) { "urn:iso:std:iso-iec:10646:ed-6:stage-30.00:amd:1:v1" }

        # it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017" do
        let(:original) { "ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017 ED5" }
        let(:pubid) { "ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017" }
        let(:urn) { "urn:iso:std:iso-iec:13818:-1:ed-5:amd:2016:v3:cor:2017:v1" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"

        it "should have type :cor" do
          expect(subject.type).to eq(:cor)
        end

        it "should have amendment as base identifier" do
          expect(subject.base.type).to eq(:amd)
        end

        it "should have base document for amendment" do
          expect(subject.base.base).to be_a(Identifier::InternationalStandard)
        end
      end

      context "ISO/IEC 14496-30:2018/FDAmd 1" do
        let(:original) { "ISO/IEC 14496-30:2018/FDAmd 1 ED2" }
        let(:pubid) { "ISO/IEC 14496-30:2018/FDAM 1" }
        let(:urn) { "urn:iso:std:iso-iec:14496:-30:ed-2:stage-draft:amd:1:v1" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO 11783-2:2012/Cor.1:2012(fr)" do
        let(:original) { "ISO 11783-2:2012/Cor.1:2012 ED2(fr)" }
        let(:pubid) { "ISO 11783-2:2012/Cor 1:2012(fr)" }
        let(:urn) { "urn:iso:std:iso:11783:-2:ed-2:cor:2012:v1:fr" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC 8802-3:2021/Amd7-2021" do
        let(:original) { "ISO/IEC 8802-3:2021/Amd 7:2021 ED3" }
        let(:pubid) { "ISO/IEC 8802-3:2021/Amd 7:2021" }
        let(:urn) { "urn:iso:std:iso-iec:8802:-3:ed-3:amd:2021:v7" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO 14451-1:2013(en,fr,other)" do
        let(:pubid) { "ISO 14451-1:2013(en,fr,other)" }
        let(:urn) { "urn:iso:std:iso:14451:-1:en,fr,other" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO 17225-1:2014(R)" do
        let(:original) { "ISO 17225-1:2014(R)" }
        let(:pubid) { "ISO 17225-1:2014(ru)" }
        let(:urn) { "urn:iso:std:iso:17225:-1:ru" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC GUIDE 2:2004(E/F/R)" do
        let(:original) { "ISO/IEC GUIDE 2:2004(E/F/R)" }
        let(:pubid) { "ISO/IEC Guide 2:2004(en,fr,ru)" }
        let(:urn) { "urn:iso:std:iso-iec:guide:2:en,fr,ru" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO 10791-6:2014/PWI Amd 1" do
        let(:original) { "ISO 10791-6:2014/PWI Amd 1 ED1" }
        let(:pubid) { "ISO 10791-6:2014/PWI Amd 1" }
        let(:urn) { "urn:iso:std:iso:10791:-6:ed-1:stage-draft:amd:1:v1" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO 11137-2:2013/FDAmd 1" do
        let(:original) { "ISO 11137-2:2013/FDAmd 1 ED3" }
        let(:pubid) { "ISO 11137-2:2013/FDAM 1" }
        let(:urn) { "urn:iso:std:iso:11137:-2:ed-3:stage-draft:amd:1:v1" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO 15002:2008/DAM 2:2020(F)" do
        let(:original) { "ISO 15002:2008/DAM 2:2020 ED2(F)" }
        let(:pubid) { "ISO 15002:2008/DAM 2:2020(fr)" }
        # let(:urn) { "urn:iso:std:iso:15002:ed-2:stage-40.00:amd:2020:v2:fr" }

        # it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC 10646-1:1993/pDCOR.2" do
        let(:original) { "ISO/IEC 10646-1:1993/pDCOR.2 ED1" }
        let(:pubid) { "ISO/IEC 10646-1:1993/CD Cor 2" }
        let(:urn) { "urn:iso:std:iso-iec:10646:-1:ed-1:stage-draft:cor:2:v1" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC 14496-12:2012/PDAM 4" do
        let(:original) { "ISO/IEC 14496-12:2012/PDAM 4 ED4" }
        let(:pubid) { "ISO/IEC 14496-12:2012/CD Amd 4" }
        let(:urn) { "urn:iso:std:iso-iec:14496:-12:ed-4:stage-draft:amd:4:v1" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC PDTR 20943-5" do
        let(:original) { "ISO/IEC PDTR 20943-5" }
        let(:pubid) { "ISO/IEC CD TR 20943-5" }
        let(:urn) { "urn:iso:std:iso-iec:tr:20943:-5:stage-draft" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC PDTS 19583-24" do
        let(:original) { "ISO/IEC PDTS 19583-24" }
        let(:pubid) { "ISO/IEC CD TS 19583-24" }
        let(:urn) { "urn:iso:std:iso-iec:ts:19583:-24:stage-draft" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "GUIDE ISO/CEI 71:2001(F)" do
        let(:original) { "GUIDE ISO/CEI 71:2001(F)" }
        let(:pubid) { "ISO/IEC Guide 71:2001(fr)" }
        let(:french_pubid) { "Guide ISO/CEI 71:2001(fr)" }
        let(:urn) { "urn:iso:std:iso-iec:guide:71:fr" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
        it_behaves_like "converts pubid to french pubid"
      end

      context "ISO 6709:2008/Cor. 1:2009" do
        let(:original) { "ISO 6709:2008/Cor. 1:2009 ED2" }
        let(:pubid) { "ISO 6709:2008/Cor 1:2009" }
        let(:urn) { "urn:iso:std:iso:6709:ed-2:cor:2009:v1" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO 10993-4:2002/Amd. 1:2006(E)" do
        let(:original) { "ISO 10993-4:2002/Amd.1:2006 ED2(E)" }
        let(:pubid) { "ISO 10993-4:2002/Amd 1:2006(en)" }
        let(:urn) { "urn:iso:std:iso:10993:-4:ed-2:amd:2006:v1:en" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"

        it "returns part without dash" do
          expect(subject.base.part).to eq("4")
        end
      end

      context "ISO/IEC 17025:2005/Cor.1:2006(fr)" do
        let(:original) { "ISO/IEC 17025:2005/Cor.1:2006 ED1(fr)" }
        let(:pubid) { "ISO/IEC 17025:2005/Cor 1:2006(fr)" }
        let(:pubid_without_date) { "ISO/IEC 17025:2005/Cor 1(fr)" }
        let(:pubid_single_letter_language) { "ISO/IEC 17025:2005/Cor 1:2006(F)" }
        let(:pubid_with_edition) { "ISO/IEC 17025:2005 ED1/Cor 1:2006(fr)" }
        let(:french_pubid) { "ISO/CEI 17025:2005/Cor.1:2006(fr)" }
        let(:urn) { "urn:iso:std:iso-iec:17025:ed-1:cor:2006:v1:fr" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
        it_behaves_like "converts pubid to french pubid"

        it "converts to pubid without date" do
          expect(subject.to_s(format: :ref_num_long, with_date: false)).to eq(pubid_without_date)
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
      end

      context "Руководство ИСО/МЭК 76" do
        let(:original) { "Руководство ИСО/МЭК 76" }
        let(:pubid) { "ISO/IEC Guide 76" }
        let(:urn) { "urn:iso:std:iso-iec:guide:76" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
        it_behaves_like "converts pubid to russian pubid"
      end

      context "ИСО/ОПМС 26000:2010(R)" do
        let(:original) { "ИСО/ОПМС 26000:2010(R)" }
        let(:pubid) { "ISO/FDIS 26000:2010(ru)" }
        let(:russian_pubid) { "ИСО/ОПМС 26000:2010(ru)" }
        let(:urn) { "urn:iso:std:iso:26000:stage-draft:ru" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
        it_behaves_like "converts pubid to russian pubid"
      end

      context "ИСО/ПМС 1956/2" do
        let(:original) { "ИСО/ПМС 1956/2" }
        let(:pubid) { "ISO/DIS 1956-2" }
        let(:urn) { "urn:iso:std:iso:1956:-2:stage-draft" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ИСО/ТС 18625" do
        let(:original) { "ИСО/ТС 18625" }
        let(:pubid) { "ISO/TS 18625" }
        let(:urn) { "urn:iso:std:iso:ts:18625" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ИСО/ТО 8517" do
        let(:original) { "ИСО/ТО 8517" }
        let(:pubid) { "ISO/TR 8517" }
        let(:urn) { "urn:iso:std:iso:tr:8517" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ИСО/ТС 18625" do
        let(:original) { "ИСО/ТС 18625" }
        let(:pubid) { "ISO/TS 18625" }
        let(:urn) { "urn:iso:std:iso:ts:18625" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "AWI IWA 36" do
        let(:original) { "AWI IWA 36" }
        let(:pubid) { "IWA/AWI 36" }
        let(:urn) { "urn:iso:std:iwa:36:stage-draft" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC WD TS 25025" do
        let(:original) { "ISO/IEC WD TS 25025" }
        let(:pubid) { "ISO/IEC WD TS 25025" }
        let(:urn) { "urn:iso:std:iso-iec:ts:25025:stage-draft" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO 19110:2005/Amd 1:2011" do
        let(:original) { "ISO 19110:2005/Amd 1:2011 ED1" }
        let(:pubid) { "ISO 19110:2005/Amd 1:2011" }
        let(:urn) { "urn:iso:std:iso:19110:ed-1:amd:2011:v1" }

        it_behaves_like "converts pubid to urn"
        it_behaves_like "converts pubid to pubid"
      end

      context "ISO 17301-1:2016/NP Amd 1.2" do
        let(:pubid) { "ISO 17301-1:2016/NP Amd 1.2" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO 17301-1:2016/FCOR 2.3" do
        let(:original) { "ISO 17301-1:2016/FCOR 2.3" }
        let(:pubid) { "ISO 17301-1:2016/FDCOR 2.3" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC/IEEE DTS 17301-1-1:2016(en)" do
        let(:pubid) { "ISO/IEC/IEEE DTS 17301-1-1:2016(en)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/IEC/IEEE FDTR 17301-1-1:2016(en)" do
        let(:pubid) { "ISO/IEC/IEEE FDTR 17301-1-1:2016(en)" }

        it_behaves_like "converts pubid to pubid"

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

      context "ISO/IEC 27006:2015/PDAM 1" do
        let(:original) { "ISO/IEC 27006:2015/PDAM 1" }
        let(:pubid) { "ISO/IEC 27006:2015/CD Amd 1" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/PRF 6709:2022" do
        let(:original) { "ISO/PRF 6709:2022" }
        let(:pubid) { "ISO/PRF 6709:2022" }
        let(:pubid_with_prf) { original }

        it_behaves_like "converts pubid to pubid with prf"
      end

      context "ISO/CD PAS 22399" do
        let(:original) { "ISO/CD PAS 22399" }
        let(:pubid) { "ISO/CD PAS 22399" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/DPAS 5643:2021(E)" do
        let(:original) { "ISO/DPAS 5643:2021(E)" }
        let(:pubid) { "ISO/DPAS 5643:2021(en)" }

        it_behaves_like "converts pubid to pubid"
      end

      context "ISO/PRF PAS 5643" do
        let(:pubid) { "ISO/PRF PAS 5643" }

        it_behaves_like "converts pubid to pubid with prf"
      end

      context "ISO/SAE DPAS 22736:2021" do
        let(:pubid) { "ISO/SAE DPAS 22736:2021" }

        it_behaves_like "converts pubid to pubid"
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

        it "has assigned IS type" do
          expect(subject.type).to eq(:is)
        end
      end

      context "ISO/TS 19115-3:2016" do
        let(:pubid) { "ISO/TS 19115-3:2016" }
        let(:urn) { "urn:iso:std:iso:ts:19115:-3" }

        it_behaves_like "converts pubid to pubid"
        it_behaves_like "converts pubid to urn"
      end

      context "ISO/R 125:1966" do
        let(:pubid) { "ISO/R 125:1966" }

        it_behaves_like "converts pubid to pubid"
      end

      describe "#parse_from_title" do
        subject { described_class.parse_from_title(title) }
        let(:title) { "#{pubid} Geographic information — Metadata — Part 1: Fundamentals" }
        let(:pubid) { "ISO 19115-1:2014" }

        it "extracts pubid from title" do
          expect(subject.to_s).to eq(pubid)
        end
      end

      describe "#transform_supplements" do
        subject { described_class.transform_supplements(supplements, base_params) }
        let(:base_params) do
          { publisher: "ISO",
            number: "1",
            year: "2016",
          }
        end
        let(:supplements) do
          [{ typed_stage: "Amd", number: "2", iteration: "3" }]
        end

        it "returns supplement as main identifier" do
          expect(subject.number).to eq("2")
          expect(subject.type).to eq(:amd)
        end

        it "assigns base identifier to supplement" do
          expect(subject.base).to eq(Identifier.new(number: "1", year: 2016))
        end

        context "when have amendment and corrigendum" do
          let(:supplements) do
            [{ typed_stage: "Amd", number: "1" },
              { typed_stage: "Cor", number: "2", iteration: "3" }]
          end

          it "returns corrigendum as main identifier" do
            expect(subject.type).to eq(:cor)
          end

          it "assigns amendment as base for corrigendum" do
            expect(subject.base.type).to eq(:amd)
          end
        end
      end

      describe "#resolve_identifier" do
        subject { described_class.resolve_identifier(type, typed_stage) }
        let(:type) { nil }
        let(:typed_stage) { nil }

        context "when TR type" do
          let(:type) { :tr }

          it { is_expected.to a_kind_of(Identifier::TechnicalReport) }
          it { expect(subject.type).to eq(:tr) }
        end

        context "when DTR" do
          let(:typed_stage) { "DTR" }

          it { is_expected.to a_kind_of(Identifier::TechnicalReport) }
          it { expect(subject.typed_stage).to eq(:dtr) }
        end

        context "when DTS" do
          let(:typed_stage) { "DTS" }

          it { is_expected.to a_kind_of(Identifier::TechnicalSpecification) }
          it { expect(subject.typed_stage).to eq(:dts) }
        end

        context "when no type or typed stage" do
          it { is_expected.to a_kind_of(Identifier::InternationalStandard) }
        end
      end
    end
  end
end
