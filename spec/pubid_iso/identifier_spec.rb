RSpec.describe Pubid::Iso::Identifier do
  subject { described_class.parse(original || pubid) }
  let(:original) { nil }
  let(:french_pubid) { original }
  let(:russian_pubid) { original }

  shared_examples "converts pubid to urn" do
    it "converts pubid to urn" do
      expect(subject.urn.to_s).to eq(urn)
      expect(subject.urn.to_s).to eq(urn)
    end
  end

  shared_examples "converts pubid to pubid" do
    it "converts pubid to pubid" do
      expect(subject.to_s).to eq(pubid)
    end
  end

  shared_examples "converts pubid to french pubid" do
    it "converts pubid to french pubid" do
      expect(subject.to_s(lang: :french)).to eq(french_pubid)
    end
  end

  shared_examples "converts pubid to russian pubid" do
    it "converts pubid to russian pubid" do
      expect(subject.to_s(lang: :russian)).to eq(russian_pubid)
    end
  end

  context "ISO 4" do
    let(:pubid) { "ISO 4" }
    let(:urn) { "urn:iso:std:iso:4" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/IEC FDIS 7816-6" do
    let(:pubid) { "ISO/IEC FDIS 7816-6" }
    let(:urn) { "urn:iso:std:iso-iec:7816:-6:stage-50.00" }

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
    let(:urn) { "urn:iso:std:iso:105:-A03:stage-50.00" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/IEC/IEEE 26512" do
    let(:pubid) { "ISO/IEC/IEEE 26512" }
    let(:urn) { "urn:iso:std:iso-iec-ieee:26512" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/IEC 30142 ED1" do
    let(:pubid) { "ISO/IEC 30142 ED1" }
    let(:urn) { "urn:iso:std:iso-iec:30142:ed-1" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO 22610:2006 Ed" do
    let(:original) { "ISO 22610:2006 Ed" }
    let(:pubid) { "ISO 22610:2006 ED1" }
    let(:urn) { "urn:iso:std:iso:22610:ed-1" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO 17121:2000 Ed 1" do
    let(:original) { "ISO 17121:2000 Ed 1" }
    let(:pubid) { "ISO 17121:2000 ED1" }
    let(:urn) { "urn:iso:std:iso:17121:ed-1" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO 11553-1 Ed.2" do
    let(:original) { "ISO 11553-1 Ed.2" }
    let(:pubid) { "ISO 11553-1 ED2" }
    let(:urn) { "urn:iso:std:iso:11553:-1:ed-2" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO 21143.2" do
    let(:pubid) { "ISO 21143.2" }
    let(:urn) { "urn:iso:std:iso:21143" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/FDIS 21420.2" do
    let(:pubid) { "ISO/FDIS 21420.2" }
    let(:urn) { "urn:iso:std:iso:21420:stage-50.00.v2" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/TR 30406:2017" do
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
    let(:urn) { "urn:iso:std:iso:23219:stage-10.00" }

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

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO 10360-1:2000/Cor 1:2002" do
    let(:pubid) { "ISO 10360-1:2000/Cor 1:2002" }
    let(:urn) { "urn:iso:std:iso:10360:-1:cor:2002:v1" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO 13688:2013/Amd 1:2021(en)" do
    let(:pubid) { "ISO 13688:2013/Amd 1:2021(en)" }
    let(:urn) { "urn:iso:std:iso:13688:amd:2021:v1:en" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/IEC 10646:2020/CD Amd 1" do
    let(:original) { "ISO/IEC 10646:2020/CD Amd 1" }
    let(:pubid) { "ISO/IEC 10646:2020/CD Amd 1" }
    let(:urn) { "urn:iso:std:iso-iec:10646:stage-30.00:amd:1:v1" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017" do
    let(:pubid) { "ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017" }
    let(:urn) { "urn:iso:std:iso-iec:13818:-1:amd:2016:v3:cor:2017:v1" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/IEC 14496-30:2018/FDAmd 1" do
    let(:original) { "ISO/IEC 14496-30:2018/FDAmd 1" }
    let(:pubid) { "ISO/IEC 14496-30:2018/FDIS Amd 1" }
    let(:urn) { "urn:iso:std:iso-iec:14496:-30:stage-50.00:amd:1:v1" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO 11783-2:2012/Cor.1:2012(fr)" do
    let(:original) { "ISO 11783-2:2012/Cor.1:2012(fr)" }
    let(:pubid) { "ISO 11783-2:2012/Cor 1:2012(fr)" }
    let(:urn) { "urn:iso:std:iso:11783:-2:cor:2012:v1:fr" }

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
    let(:original) { "ISO 10791-6:2014/PWI Amd 1" }
    let(:pubid) { "ISO 10791-6:2014/PWI Amd 1" }
    let(:urn) { "urn:iso:std:iso:10791:-6:stage-00.00:amd:1:v1" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO 11137-2:2013/FDAmd 1" do
    let(:original) { "ISO 11137-2:2013/FDAmd 1" }
    let(:pubid) { "ISO 11137-2:2013/FDIS Amd 1" }
    let(:urn) { "urn:iso:std:iso:11137:-2:stage-50.00:amd:1:v1" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO 15002:2008/DAM 2:2020(F)" do
    let(:original) { "ISO 15002:2008/DAM 2:2020(F)" }
    let(:pubid) { "ISO 15002:2008/DIS Amd 2:2020(fr)" }
    let(:urn) { "urn:iso:std:iso:15002:stage-40.00:amd:2020:v2:fr" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/IEC 10646-1:1993/pDCOR.2" do
    let(:original) { "ISO/IEC 10646-1:1993/pDCOR.2" }
    let(:pubid) { "ISO/IEC 10646-1:1993/CD Cor 2" }
    let(:urn) { "urn:iso:std:iso-iec:10646:-1:stage-30.00:cor:2:v1" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/IEC 14496-12/PDAM 4" do
    let(:original) { "ISO/IEC 14496-12/PDAM 4" }
    let(:pubid) { "ISO/IEC 14496-12/CD Amd 4" }
    let(:urn) { "urn:iso:std:iso-iec:14496:-12:stage-30.00:amd:4:v1" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/IEC PDTR 20943-5" do
    let(:original) { "ISO/IEC PDTR 20943-5" }
    let(:pubid) { "ISO/IEC TR CD 20943-5" }
    let(:urn) { "urn:iso:std:iso-iec:tr:20943:-5:stage-30.00" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/IEC PDTS 19583-24" do
    let(:original) { "ISO/IEC PDTS 19583-24" }
    let(:pubid) { "ISO/IEC TS CD 19583-24" }
    let(:urn) { "urn:iso:std:iso-iec:ts:19583:-24:stage-30.00" }

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

  context "ISO/IEC 17025:2005/Cor.1:2006(fr)" do
    let(:original) { "ISO/IEC 17025:2005/Cor.1:2006(fr)" }
    let(:pubid) { "ISO/IEC 17025:2005/Cor 1:2006(fr)" }
    let(:pubid_without_date) { "ISO/IEC 17025/Cor 1:2006(fr)" }
    let(:pubid_single_letter_language) { "ISO/IEC 17025:2005/Cor 1:2006(F)" }
    let(:french_pubid) { "ISO/CEI 17025:2005/Cor.1:2006(fr)" }
    let(:urn) { "urn:iso:std:iso-iec:17025:cor:2006:v1:fr" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
    it_behaves_like "converts pubid to french pubid"

    it "converts to pubid without date" do
      expect(subject.to_s(with_date: false)).to eq(pubid_without_date)
    end

    it "converts to pubid with single letter language code" do
      expect(subject.to_s(with_language_code: :single)).to eq(pubid_single_letter_language)
    end
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
    let(:urn) { "urn:iso:std:iso:26000:stage-50.00:ru" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
    it_behaves_like "converts pubid to russian pubid"
  end

  context "ИСО/ПМС 1956/2" do
    let(:original) { "ИСО/ПМС 1956/2" }
    let(:pubid) { "ISO/DIS 1956-2" }
    let(:urn) { "urn:iso:std:iso:1956:-2:stage-40.00" }

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
    let(:urn) { "urn:iso:std:iwa:36:stage-20.00" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/IEC WD TS 25025" do
    let(:original) { "ISO/IEC WD TS 25025" }
    let(:pubid) { "ISO/IEC TS WD 25025" }
    let(:urn) { "urn:iso:std:iso-iec:ts:25025:stage-20.20" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO 19110/Amd 1:2011" do
    let(:original) { "ISO 19110/Amd 1:2011" }
    let(:pubid) { "ISO 19110/Amd 1:2011" }
    let(:urn) { "urn:iso:std:iso:19110:amd:2011:v1" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO TC 184/SC 4 N1110" do
    let(:pubid) { "ISO TC 184/SC 4 N1110" }
    let(:urn) { "urn:iso:doc:iso:tc:184:sc:4:1110" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/IEC JTC 1/SC 32 N1001" do
    let(:pubid) { "ISO/IEC JTC 1/SC 32 N1001" }
    let(:urn) { "urn:iso:doc:iso-iec:jtc:1:sc:32:1001" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/TC 184/SC/QC 4 N265" do
    let(:pubid) { "ISO TC 184/SC/QC 4 N265" }
    let(:urn) { "urn:iso:doc:iso:tc:184:sc:4:qc:265" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/TC 46 N 3064" do
    let(:original) { "ISO/TC 46 N 3064" }
    let(:pubid) { "ISO TC 46 N3064" }
    let(:urn) { "urn:iso:doc:iso:tc:46:3064" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/TC 184/SC 4/WG 12 N10897" do
    let(:original) { "ISO/TC 184/SC 4/WG 12 N10897" }
    let(:pubid) { "ISO TC 184/SC 4/WG 12 N10897" }
    let(:urn) { "urn:iso:doc:iso:tc:184:sc:4:wg:12:10897" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/TC 154/WG 5 N152" do
    let(:original) { "ISO/TC 154/WG 5 N152" }
    let(:pubid) { "ISO TC 154/WG 5 N152" }
    let(:urn) { "urn:iso:doc:iso:tc:154:wg:5:152" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "ISO/TMB/DMT 154/WG 5 N152" do
    let(:original) { "ISO/TMB/DMT 154/WG 5 N152" }
    let(:pubid) { "ISO DMT/TMB 154/WG 5 N152" }
    let(:urn) { "urn:iso:doc:iso:dmt:tmb:154:wg:5:152" }

    it_behaves_like "converts pubid to urn"
    it_behaves_like "converts pubid to pubid"
  end

  context "when assigns amendment" do
    let(:original) { "ISO/IEC 17025:2005" }
    let(:pubid) { "ISO/IEC 17025:2005/Amd 1:2010" }

    it "generates correct PubID with amendment" do
      subject.amendments = [Pubid::Iso::Amendment.new(version: 1, number: 2010)]
      expect(subject.to_s).to eq(pubid)
    end
  end

  context "when assigns corrigendum" do
    let(:original) { "ISO/IEC 17025:2005" }
    let(:pubid) { "ISO/IEC 17025:2005/Cor 1:2010" }

    it "generates correct PubID with corrigendum" do
      subject.corrigendums = [Pubid::Iso::Corrigendum.new(version: 1, number: 2010)]
      expect(subject.to_s).to eq(pubid)
    end
  end

  describe "#parse_from_title" do
    subject { described_class.parse_from_title(title) }
    let(:title) { "#{pubid} Geographic information — Metadata — Part 1: Fundamentals" }
    let(:pubid) { "ISO 19115-1:2014" }

    it "extracts pubid from title" do
      expect(subject.to_s).to eq(pubid)
    end
  end
end
