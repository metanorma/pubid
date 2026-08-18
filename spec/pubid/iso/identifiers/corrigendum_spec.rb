require "spec_helper"

RSpec.describe Pubid::Iso::Identifiers::Corrigendum do
  subject { described_class }


  # Test basic corrigendum identifiers
  context "basic corrigendum identifiers" do
    describe "ISO 10360-1:2000/Cor 1:2002" do
      subject { "ISO 10360-1:2000/Cor 1:2002" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:10360:-1:cor:2002:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("10360")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2000")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2002")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 10360-1/Cor 1:2002" do
      subject { "ISO 10360-1/Cor 1:2002" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:10360:-1:cor:2002:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("10360")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date).to be_nil
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2002")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEEE 11073-10418:2014/Cor 1:2016" do
      subject { "ISO/IEEE 11073-10418:2014/Cor 1:2016" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-ieee:11073:-10418:cor:2016:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.publisher.copublisher.first).to eq("IEEE")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("11073")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("10418")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2014")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2016")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 123:1999/Cor 1" do
      subject { "ISO 123:1999/Cor 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:123:cor:1:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("123")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("1999")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test legacy format normalization
  context "legacy format normalization" do
    describe "ISO 105-G01:1993/COR 1:1995" do
      subject { "ISO 105-G01:1993/COR 1:1995" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # V2 preserves original format
      let(:normalized) do
        "ISO 105-G01:1993/COR 1:1995"
      end
      let(:urn) { "urn:iso:std:iso:105:-G01:cor:1995:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("105")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("G01")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("1993")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("1995")
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 6709:2008/Cor. 1:2009" do
      subject { "ISO 6709:2008/Cor. 1:2009" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO 6709:2008/Cor 1:2009" }
      let(:urn) { "urn:iso:std:iso:6709:cor:2009:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("6709")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2008")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2009")
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 9606-1:2012/Cor.2:2013(F)" do
      subject { "ISO 9606-1:2012/Cor.2:2013(F)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO 9606-1:2012/Cor 2:2013(fr)" }
      let(:urn) { "urn:iso:std:iso:9606:-1:cor:2013:v2:fr" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("9606")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2012")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2013")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[fr])
      end

      it "normalizes format and language" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC 17025:2005/Cor.1:2006(fr)" do
      subject { "ISO/IEC 17025:2005/Cor.1:2006(fr)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/IEC 17025:2005/Cor 1:2006(fr)" }
      let(:urn) { "urn:iso:std:iso-iec:17025:cor:2006:v1:fr" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("17025")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2005")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2006")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[fr])
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test corrigendum stages
  context "corrigendum stages" do
    context "preliminary" do
      describe "ISO 3822-3:1997/PWI Cor 1" do
        subject { "ISO 3822-3:1997/PWI Cor 1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:3822:-3:stage-00.00:cor:1:v1" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("3822")
        end

        it "parses base identifier part" do
          expect(parsed.base.part.value).to eq("3")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("1997")
        end

        it "parses corrigendum number" do
          expect(parsed.number.value).to eq("1")
        end

        it "parses corrigendum date" do
          expect(parsed.date).to be_nil
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("proposal")
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("cor")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "proposal" do
      describe "ISO 10303-111:2007/NP Cor 2" do
        subject { "ISO 10303-111:2007/NP Cor 2" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:10303:-111:stage-10.00:cor:2:v1" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("10303")
        end

        it "parses base identifier part" do
          expect(parsed.base.part.value).to eq("111")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("2007")
        end

        it "parses corrigendum number" do
          expect(parsed.number.value).to eq("2")
        end

        it "parses corrigendum date" do
          expect(parsed.date).to be_nil
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("proposal")
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("cor")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "preparatory" do
      describe "ISO 13431:1999/AWI Cor 1" do
        subject { "ISO 13431:1999/AWI Cor 1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:13431:stage-10.99:cor:1:v1" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("13431")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("1999")
        end

        it "parses corrigendum number" do
          expect(parsed.number.value).to eq("1")
        end

        it "parses corrigendum date" do
          expect(parsed.date).to be_nil
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("preliminary")
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("cor")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO 13431:1999/WD Cor 1" do
        subject { "ISO 13431:1999/WD Cor 1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:13431:stage-20.20:cor:1:v1" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("13431")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("1999")
        end

        it "parses corrigendum number" do
          expect(parsed.number.value).to eq("1")
        end

        it "parses corrigendum date" do
          expect(parsed.date).to be_nil
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("working_draft")
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("cor")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "committee" do
      describe "ISO 3864-2:2004/CD Cor 1" do
        subject { "ISO 3864-2:2004/CD Cor 1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:3864:-2:CD:cor:1:v1" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("3864")
        end

        it "parses base identifier part" do
          expect(parsed.base.part.value).to eq("2")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("2004")
        end

        it "parses corrigendum number" do
          expect(parsed.number.value).to eq("1")
        end

        it "parses corrigendum date" do
          expect(parsed.date).to be_nil
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("cd")
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("cor")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO/IEC ISP 10611-4:1997/CD Cor 2" do
        subject { "ISO/IEC ISP 10611-4:1997/CD Cor 2" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:isp:10611:-4:CD:cor:2:v1" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.base.publisher.copublisher.first).to eq("IEC")
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("10611")
        end

        it "parses base identifier part" do
          expect(parsed.base.part.value).to eq("4")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("1997")
        end

        it "parses base identifier type" do
          expect(parsed.base.typed_stage.type_code).to eq("isp")
        end

        it "parses corrigendum number" do
          expect(parsed.number.value).to eq("2")
        end

        it "parses corrigendum date" do
          expect(parsed.date).to be_nil
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("cd")
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("cor")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO/IEC 15408-2:1999/CD Cor 1" do
        subject { "ISO/IEC 15408-2:1999/CD Cor 1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:15408:-2:CD:cor:1:v1" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.base.publisher.copublisher.first).to eq("IEC")
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("15408")
        end

        it "parses base identifier part" do
          expect(parsed.base.part.value).to eq("2")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("1999")
        end

        it "parses corrigendum number" do
          expect(parsed.number.value).to eq("1")
        end

        it "parses corrigendum date" do
          expect(parsed.date).to be_nil
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("cd")
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("cor")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "enquiry" do
      describe "ISO/IEC 14496-12/DCOR 1" do
        subject { "ISO/IEC 14496-12/DCOR 1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        # V2 preserves original format
        let(:normalized) do
          "ISO/IEC 14496-12/DCOR 1"
        end
        let(:urn) { "urn:iso:std:iso-iec:14496:-12:DCOR:cor:1:v1" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.base.publisher.copublisher.first).to eq("IEC")
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("14496")
        end

        it "parses base identifier part" do
          expect(parsed.base.part.value).to eq("12")
        end

        it "parses base identifier date" do
          expect(parsed.base.date).to be_nil
        end

        it "parses corrigendum number" do
          expect(parsed.number.value).to eq("1")
        end

        it "parses corrigendum date" do
          expect(parsed.date).to be_nil
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("dcor")
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("cor")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "approval" do
      describe "ISO/TR 23455:2019/FDCor 1" do
        subject { "ISO/TR 23455:2019/FDCor 1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:tr:23455:FDCOR:cor:1:v1" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("23455")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("2019")
        end

        it "parses base identifier type" do
          expect(parsed.base.typed_stage.type_code).to eq("tr")
        end

        it "parses corrigendum number" do
          expect(parsed.number.value).to eq("1")
        end

        it "parses corrigendum date" do
          expect(parsed.date).to be_nil
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("fdcor")
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("cor")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end
  end

  # Test legacy stage variations
  context "legacy stage variations" do
    describe "ISO/IEC 10646-1:1993/pDCOR.2" do
      subject { "ISO/IEC 10646-1:1993/pDCOR.2" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/IEC 10646-1:1993/CD Cor 2" }
      let(:urn) { "urn:iso:std:iso-iec:10646:-1:CD:cor:2:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("10646")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("1993")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses corrigendum date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("cd")
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test stage iterations
  context "stage iterations" do
    describe "ISO 17301-1:2016/DCor 1.3:2002" do
      subject { "ISO 17301-1:2016/DCor 1.3:2002" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:17301:-1:DCOR.3:cor:2002:v1.3" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("17301")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2016")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2002")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("dcor")
      end

      it "parses iteration" do
        expect(parsed.stage_iteration.number).to eq("3")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 17301-1:2016/DCor 2.3" do
      subject { "ISO 17301-1:2016/DCor 2.3" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:17301:-1:DCOR.3:cor:2:v1.3" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("17301")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2016")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses corrigendum date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("dcor")
      end

      it "parses iteration" do
        expect(parsed.stage_iteration.number).to eq("3")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 17301-1:2016/DCOR 1.3:2002" do
      subject { "ISO 17301-1:2016/DCOR 1.3:2002" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # V2 preserves original format
      let(:normalized) do
        "ISO 17301-1:2016/DCOR 1.3:2002"
      end
      let(:urn) { "urn:iso:std:iso:17301:-1:DCOR.3:cor:2002:v1.3" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("17301")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2016")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2002")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("dcor")
      end

      it "parses iteration" do
        expect(parsed.stage_iteration.number).to eq("3")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 17301-1:2016/FDCor 1.3:2022" do
      subject { "ISO 17301-1:2016/FDCor 1.3:2022" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:17301:-1:FDCOR.3:cor:2022:v1.3" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("17301")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2016")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2022")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("fdcor")
      end

      it "parses iteration" do
        expect(parsed.stage_iteration.number).to eq("3")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 17301-1:2016/FDCOR 1.3:2022" do
      subject { "ISO 17301-1:2016/FDCOR 1.3:2022" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # V2 preserves original format
      let(:normalized) do
        "ISO 17301-1:2016/FDCOR 1.3:2022"
      end
      let(:urn) { "urn:iso:std:iso:17301:-1:FDCOR.3:cor:2022:v1.3" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("17301")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2016")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2022")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("fdcor")
      end

      it "parses iteration" do
        expect(parsed.stage_iteration.number).to eq("3")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 17301-1:2016/FDCor 2.3" do
      subject { "ISO 17301-1:2016/FDCor 2.3" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:17301:-1:FDCOR.3:cor:2:v1.3" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("17301")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2016")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses corrigendum date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("fdcor")
      end

      it "parses iteration" do
        expect(parsed.stage_iteration.number).to eq("3")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 17301-1:2016/FCOR 2.3" do
      subject { "ISO 17301-1:2016/FCOR 2.3" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # V2 uses short_abbr for rendering
      let(:normalized) do
        "ISO 17301-1:2016/FDCOR 2.3"
      end
      let(:urn) { "urn:iso:std:iso:17301:-1:FDCOR.3:cor:2:v1.3" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("17301")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2016")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses corrigendum date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("fdcor")
      end

      it "parses iteration" do
        expect(parsed.stage_iteration.number).to eq("3")
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test corrigendum of amendment
  context "corrigendum of amendment" do
    describe "ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017" do
      subject { "ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:13818:-1:amd:2016:v3:cor:2017:v1" }

      it "parses publisher" do
        expect(parsed.base.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.base.publisher.copublisher.first).to eq("IEC")
      end

      it "has amendment as base identifier" do
        expect(parsed.base.typed_stage.type_code).to eq("amd")
      end

      it "parses amendment base identifier number" do
        expect(parsed.base.base.number.value).to eq("13818")
      end

      it "parses amendment base identifier part" do
        expect(parsed.base.base.part.value).to eq("1")
      end

      it "parses amendment base identifier date" do
        expect(parsed.base.base.date.year).to eq("2015")
      end

      it "parses amendment number" do
        expect(parsed.base.number.value).to eq("3")
      end

      it "parses amendment date" do
        expect(parsed.base.date.year).to eq("2016")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2017")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC 15938-7:2003/Amd 5:2010/CD Cor 1" do
      subject { "ISO/IEC 15938-7:2003/Amd 5:2010/CD Cor 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) do
        "urn:iso:std:iso-iec:15938:-7:amd:2010:v5:CD:cor:1:v1"
      end

      it "parses publisher" do
        expect(parsed.base.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.base.publisher.copublisher.first).to eq("IEC")
      end

      it "has amendment as base identifier" do
        expect(parsed.base.typed_stage.type_code).to eq("amd")
      end

      it "parses amendment base identifier number" do
        expect(parsed.base.base.number.value).to eq("15938")
      end

      it "parses amendment base identifier part" do
        expect(parsed.base.base.part.value).to eq("7")
      end

      it "parses amendment base identifier date" do
        expect(parsed.base.base.date.year).to eq("2003")
      end

      it "parses amendment number" do
        expect(parsed.base.number.value).to eq("5")
      end

      it "parses amendment date" do
        expect(parsed.base.date.year).to eq("2010")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("cd")
      end

      it "round-trips with V2 normalization" do
        expect(parsed.to_s(with_edition: true)).to eq("ISO/IEC 15938-7:2003/AMD 5:2010/CD Cor 1")
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test corrigendum of supplement
  context "corrigendum of supplement" do
    describe "ISO/IEC Guide 98-3:2008/Suppl 1:2008/Cor 1:2009" do
      subject { "ISO/IEC Guide 98-3:2008/Suppl 1:2008/Cor 1:2009" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:guide:98:-3:sup:2008:v1:cor:2009:v1" }

      it "parses publisher" do
        expect(parsed.base.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.base.publisher.copublisher.first).to eq("IEC")
      end

      it "has supplement as base identifier" do
        expect(parsed.base.typed_stage.type_code).to eq("suppl")
      end

      it "parses supplement base identifier number" do
        expect(parsed.base.base.number.value).to eq("98")
      end

      it "parses supplement base identifier part" do
        expect(parsed.base.base.part.value).to eq("3")
      end

      it "parses supplement base identifier date" do
        expect(parsed.base.base.date.year).to eq("2008")
      end

      it "parses supplement base identifier type" do
        expect(parsed.base.base.typed_stage.type_code).to eq("guide")
      end

      it "parses supplement number" do
        expect(parsed.base.number.value).to eq("1")
      end

      it "parses supplement date" do
        expect(parsed.base.date.year).to eq("2008")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2009")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC Guide 98-3 ED1/Suppl 1:2008/Cor 1:2009" do
      subject { "ISO/IEC Guide 98-3 ED1/Suppl 1:2008/Cor 1:2009" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) do
        "urn:iso:std:iso-iec:guide:98:-3:ed-1:sup:2008:v1:cor:2009:v1"
      end

      it "parses publisher" do
        expect(parsed.base.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.base.publisher.copublisher.first).to eq("IEC")
      end

      it "has supplement as base identifier" do
        expect(parsed.base.typed_stage.type_code).to eq("suppl")
      end

      it "parses supplement base identifier number" do
        expect(parsed.base.base.number.value).to eq("98")
      end

      it "parses supplement base identifier part" do
        expect(parsed.base.base.part.value).to eq("3")
      end

      it "parses supplement base identifier date" do
        expect(parsed.base.base.date).to be_nil
      end

      it "parses supplement base identifier type" do
        expect(parsed.base.base.typed_stage.type_code).to eq("guide")
      end

      it "parses supplement base identifier edition" do
        expect(parsed.base.base.edition.number.value).to eq("1")
      end

      it "parses supplement number" do
        expect(parsed.base.number.value).to eq("1")
      end

      it "parses supplement date" do
        expect(parsed.base.date.year).to eq("2008")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2009")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test editions with languages
  context "editions with languages" do
    describe "ISO 11783-2:2012/Cor.1:2012(fr)" do
      subject { "ISO 11783-2:2012/Cor.1:2012(fr)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO 11783-2:2012/Cor 1:2012(fr)" }
      let(:urn) { "urn:iso:std:iso:11783:-2:cor:2012:v1:fr" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("11783")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("2")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2012")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2012")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[fr])
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 11783-2:2012/Cor.1:2012 ED2(fr)" do
      subject { "ISO 11783-2:2012/Cor.1:2012 ED2(fr)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO 11783-2:2012/Cor 1:2012 ED2(fr)" }
      let(:urn) { "urn:iso:std:iso:11783:-2:ed-2:cor:2012:v1:fr" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("11783")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("2")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2012")
      end

      it "parses edition" do
        expect(parsed.edition&.value).to eq("2")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2012")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[fr])
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 11783-2:2012/Cor 1:2012(fr)" do
      subject { "ISO 11783-2:2012/Cor 1:2012(fr)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:11783:-2:cor:2012:v1:fr" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("11783")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("2")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2012")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2012")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[fr])
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 11783-2 ED2/Cor 1:2012(fr)" do
      subject { "ISO 11783-2 ED2/Cor 1:2012(fr)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:11783:-2:ed-2:cor:2012:v1:fr" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("11783")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("2")
      end

      it "parses base identifier date" do
        expect(parsed.base.date).to be_nil
      end

      it "parses edition" do
        expect(parsed.base.edition&.value).to eq("2")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2012")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[fr])
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC 17025:2005/Cor 1" do
      subject { "ISO/IEC 17025:2005/Cor 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:17025:cor:1:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("17025")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2005")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC 17025:2005/Cor 1:2006(F)" do
      subject { "ISO/IEC 17025:2005/Cor 1:2006(F)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/IEC 17025:2005/Cor 1:2006(fr)" }
      let(:urn) { "urn:iso:std:iso-iec:17025:cor:2006:v1:fr" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("17025")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2005")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2006")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[fr])
      end

      it "normalizes language format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC 17025:2005/Cor.1:2006 ED1(fr)" do
      subject { "ISO/IEC 17025:2005/Cor.1:2006 ED1(fr)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/IEC 17025:2005/Cor 1:2006 ED1(fr)" }
      let(:urn) { "urn:iso:std:iso-iec:17025:ed-1:cor:2006:v1:fr" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("17025")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2005")
      end

      it "parses edition" do
        expect(parsed.edition&.value).to eq("1")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2006")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[fr])
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC 17025:2005 ED1/Cor 1:2006(fr)" do
      subject { "ISO/IEC 17025:2005 ED1/Cor 1:2006(fr)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:17025:ed-1:cor:2006:v1:fr" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("17025")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2005")
      end

      it "parses edition" do
        expect(parsed.base.edition&.value).to eq("1")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2006")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[fr])
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test corrigendum of amendment with editions
  context "corrigendum of amendment with editions" do
    describe "ISO/IEC 13818-1 ED5/Amd 3:2016/Cor 1:2017" do
      subject { "ISO/IEC 13818-1 ED5/Amd 3:2016/Cor 1:2017" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:13818:-1:ed-5:amd:2016:v3:cor:2017:v1" }

      it "parses publisher" do
        expect(parsed.base.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.base.publisher.copublisher.first).to eq("IEC")
      end

      it "has amendment as base identifier" do
        expect(parsed.base.typed_stage.type_code).to eq("amd")
      end

      it "parses amendment base identifier number" do
        expect(parsed.base.base.number.value).to eq("13818")
      end

      it "parses amendment base identifier part" do
        expect(parsed.base.base.part.value).to eq("1")
      end

      it "parses amendment base identifier date" do
        expect(parsed.base.base.date).to be_nil
      end

      it "parses amendment base identifier edition" do
        expect(parsed.base.base.edition.number.value).to eq("5")
      end

      it "parses amendment number" do
        expect(parsed.base.number.value).to eq("3")
      end

      it "parses amendment date" do
        expect(parsed.base.date.year).to eq("2016")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2017")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017 ED5" do
      subject { "ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017 ED5" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:13818:-1:ed-5:amd:2016:v3:cor:2017:v1" }

      it "parses publisher" do
        expect(parsed.base.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.base.publisher.copublisher.first).to eq("IEC")
      end

      it "has amendment as base identifier" do
        expect(parsed.base.typed_stage.type_code).to eq("amd")
      end

      it "parses amendment base identifier number" do
        expect(parsed.base.base.number.value).to eq("13818")
      end

      it "parses amendment base identifier part" do
        expect(parsed.base.base.part.value).to eq("1")
      end

      it "parses amendment base identifier date" do
        expect(parsed.base.base.date.year).to eq("2015")
      end

      it "parses edition" do
        expect(parsed.edition&.value).to eq("5")
      end

      it "parses amendment number" do
        expect(parsed.base.number.value).to eq("3")
      end

      it "parses amendment date" do
        expect(parsed.base.date.year).to eq("2016")
      end

      it "parses corrigendum number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses corrigendum date" do
        expect(parsed.date.year).to eq("2017")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("cor")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Cor")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end
end
