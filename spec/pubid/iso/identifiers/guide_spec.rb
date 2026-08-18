require "spec_helper"

RSpec.describe Pubid::Iso::Identifiers::Guide do
  subject { described_class }


  # Test normal dated guide
  context "parse normal dated guide" do
    # ISO GUIDE 2:1978
    describe "ISO GUIDE 2:1978" do
      subject { "ISO GUIDE 2:1978" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO Guide 2:1978" }
      let(:urn) { "urn:iso:std:iso:guide:2" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses part" do
        expect(parsed.part&.value).to be_nil
      end

      it "parses date" do
        expect(parsed.date.year).to eq("1978")
      end

      it "normalizes format" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("guide")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Guide")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test normal undated guide
  context "parse normal undated guide" do
    # ISO/Guide 1
    describe "ISO/Guide 1" do
      subject { "ISO/Guide 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO Guide 1" }
      let(:urn) { "urn:iso:std:iso:guide:1" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses part" do
        expect(parsed.part&.value).to be_nil
      end

      it "parses date" do
        expect(parsed.date).to be_nil
      end

      it "normalizes format" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("guide")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Guide")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # ISO/GUIDE 1
    describe "ISO/GUIDE 1" do
      subject { "ISO/GUIDE 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO Guide 1" }
      let(:urn) { "urn:iso:std:iso:guide:1" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses part" do
        expect(parsed.part&.value).to be_nil
      end

      it "parses date" do
        expect(parsed.date).to be_nil
      end

      it "normalizes format" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("guide")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Guide")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test format normalization
  context "format normalization" do
    describe "ISO GUIDE 1:1972" do
      subject { "ISO GUIDE 1:1972" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO Guide 1:1972" }
      let(:urn) { "urn:iso:std:iso:guide:1" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("1972")
      end

      it "normalizes format" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("guide")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Guide")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test copublisher guides
  context "copublishers" do
    context "copublisher as IEC" do
      # ISO/IEC Guide 17:2016
      describe "ISO/IEC Guide 17:2016" do
        subject { "ISO/IEC Guide 17:2016" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:guide:17" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("17")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2016")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "provides stage code" do
          expect(parsed.typed_stage.stage_code).to eq("published")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      # ISO/IEC GUIDE 38:1983 (uppercase GUIDE)
      describe "ISO/IEC GUIDE 38:1983" do
        subject { "ISO/IEC GUIDE 38:1983" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:normalized) { "ISO/IEC Guide 38:1983" }
        let(:urn) { "urn:iso:std:iso-iec:guide:38" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("38")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("1983")
        end

        it "normalizes format" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "provides stage code" do
          expect(parsed.typed_stage.stage_code).to eq("published")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      # ISO/IEC GUIDE 39:1988 (uppercase GUIDE)
      describe "ISO/IEC GUIDE 39:1988" do
        subject { "ISO/IEC GUIDE 39:1988" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:normalized) { "ISO/IEC Guide 39:1988" }
        let(:urn) { "urn:iso:std:iso-iec:guide:39" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("39")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("1988")
        end

        it "normalizes format" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "provides stage code" do
          expect(parsed.typed_stage.stage_code).to eq("published")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      # ISO/IEC Guide 41:2003 (mixed case)
      describe "ISO/IEC Guide 41:2003" do
        subject { "ISO/IEC Guide 41:2003" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:guide:41" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("41")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2003")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "provides stage code" do
          expect(parsed.typed_stage.stage_code).to eq("published")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      # ISO/IEC Guide 46:2017
      describe "ISO/IEC Guide 46:2017" do
        subject { "ISO/IEC Guide 46:2017" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:guide:46" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("46")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2017")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "provides stage code" do
          expect(parsed.typed_stage.stage_code).to eq("published")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      # ISO/IEC Guide 51:2014
      describe "ISO/IEC Guide 51:2014" do
        subject { "ISO/IEC Guide 51:2014" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:guide:51" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("51")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2014")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "provides stage code" do
          expect(parsed.typed_stage.stage_code).to eq("published")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      # ISO/IEC Guide 63:2019
      describe "ISO/IEC Guide 63:2019" do
        subject { "ISO/IEC Guide 63:2019" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:guide:63" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("63")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2019")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "provides stage code" do
          expect(parsed.typed_stage.stage_code).to eq("published")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      # ISO/IEC Guide 71:2014
      describe "ISO/IEC Guide 71:2014" do
        subject { "ISO/IEC Guide 71:2014" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:guide:71" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("71")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2014")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "provides stage code" do
          expect(parsed.typed_stage.stage_code).to eq("published")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end
  end

  # Test parts
  context "parts" do
    describe "ISO/IEC Guide 98-3:2008" do
      subject { "ISO/IEC Guide 98-3:2008" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:guide:98:-3" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("98")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("3")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2008")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("guide")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Guide")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test stage variations for guides
  context "stages" do
    context "proposal" do
      describe "ISO/NP Guide 30" do
        subject { "ISO/NP Guide 30" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:normalized) { "ISO NP Guide 30" }
        let(:urn) { "urn:iso:std:iso:guide:30:stage-10.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("30")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("np")
        end

        it "normalizes format" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO/IEC NP Guide 98:1995" do
        subject { "ISO/IEC NP Guide 98:1995" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:guide:98:stage-10.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("98")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("1995")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("np")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "preparatory" do
      describe "ISO/IEC AWI Guide 14" do
        subject { "ISO/IEC AWI Guide 14" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:guide:14:stage-10.99" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("14")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("awi")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO/AWI Guide 82" do
        subject { "ISO/AWI Guide 82" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:normalized) { "ISO AWI Guide 82" }
        let(:urn) { "urn:iso:std:iso:guide:82:stage-10.99" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("82")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("awi")
        end

        it "normalizes format" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "committee" do
      describe "ISO/IEC CD Guide 98-5" do
        subject { "ISO/IEC CD Guide 98-5" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:guide:98:-5:CD" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("98")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("5")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("cd")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO/CD Guide 73" do
        subject { "ISO/CD Guide 73" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:normalized) { "ISO CD Guide 73" }
        let(:urn) { "urn:iso:std:iso:guide:73:CD" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("73")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("cd")
        end

        it "normalizes format" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "enquiry" do
      describe "ISO/DGUIDE 84:2024(en)" do
        subject { "ISO/DGUIDE 84:2024(en)" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:normalized) { "ISO DGuide 84:2024(en)" }
        let(:urn) { "urn:iso:std:iso:guide:84:stage-40.00:en" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("84")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2024")
        end

        it "parses languages" do
          expect(parsed.languages.map(&:code)).to eq(%w[en])
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("dguide")
        end

        it "normalizes format" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO/DGUIDE 83:2023(E)" do
        subject { "ISO/DGUIDE 83:2023(E)" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        # V2 preserves original language format
        let(:normalized) do
          "ISO DGuide 83:2023(E)"
        end
        let(:urn) { "urn:iso:std:iso:guide:83:stage-40.00:en" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("83")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2023")
        end

        it "parses languages" do
          expect(parsed.languages.map(&:code)).to eq(%w[en])
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("dguide")
        end

        it "normalizes language format" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO/DGuide 31(en)" do
        subject { "ISO/DGuide 31(en)" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:normalized) { "ISO DGuide 31(en)" }
        let(:urn) { "urn:iso:std:iso:guide:31:stage-40.00:en" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("31")
        end

        it "parses languages" do
          expect(parsed.languages.map(&:code)).to eq(%w[en])
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("dguide")
        end

        it "normalizes format" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "draft guides" do
      describe "ISO/DGuide 84" do
        subject { "ISO/DGuide 84" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:normalized) { "ISO DGuide 84" }
        let(:pubid) { "ISO DGuide 84" }
        let(:urn) { "urn:iso:std:iso:guide:84:stage-40.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("84")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("dguide")
        end

        it "normalizes format" do
          expect(parsed.to_s).to eq(pubid)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO DGUIDE 84" do
        subject { "ISO DGUIDE 84" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:normalized) { "ISO DGuide 84" }
        let(:urn) { "urn:iso:std:iso:guide:84:stage-40.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("84")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("dguide")
        end

        it "normalizes format" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "approval" do
      describe "ISO/IEC FDGuide 98-6:2020(E)" do
        subject { "ISO/IEC FDGuide 98-6:2020(E)" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        # V2 preserves original language format
        let(:normalized) do
          "ISO/IEC FDGuide 98-6:2020(E)"
        end
        let(:urn) { "urn:iso:std:iso-iec:guide:98:-6:stage-50.00:en" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("98")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("6")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2020")
        end

        it "parses languages" do
          expect(parsed.languages.map(&:code)).to eq(%w[en])
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("fdguide")
        end

        it "normalizes language format" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO/IEC FDGuide 98-1" do
        subject { "ISO/IEC FDGuide 98-1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:guide:98:-1:stage-50.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("98")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("1")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("fdguide")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO/IEC FD GUIDE 98-1" do
        subject { "ISO/IEC FD GUIDE 98-1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:normalized) { "ISO/IEC FDGuide 98-1" }
        let(:urn) { "urn:iso:std:iso-iec:guide:98:-1:stage-50.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("98")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("1")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("fdguide")
        end

        it "normalizes format" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO/IEC FD Guide 98-1" do
        subject { "ISO/IEC FD Guide 98-1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:normalized) { "ISO/IEC FDGuide 98-1" }
        let(:urn) { "urn:iso:std:iso-iec:guide:98:-1:stage-50.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("98")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("1")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("fdguide")
        end

        it "normalizes format" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "publication" do
      describe "ISO/PRF Guide 99998" do
        subject { "ISO/PRF Guide 99998" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:normalized) { "ISO PRF Guide 99998" }
        let(:urn) { "urn:iso:std:iso:guide:99998:stage-50.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("99998")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("prf")
        end

        it "normalizes format" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO/PRF Guide 35" do
        subject { "ISO/PRF Guide 35" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:normalized) { "ISO PRF Guide 35" }
        let(:urn) { "urn:iso:std:iso:guide:35:stage-50.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("35")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("prf")
        end

        it "normalizes format" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("guide")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end
  end

  # Test stage iterations
  context "stage iterations" do
    describe "ISO/IEC CD Guide 99.2" do
      subject { "ISO/IEC CD Guide 99.2" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:guide:99:CD.2" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("99")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("cd")
      end

      it "parses iteration" do
        expect(parsed.stage_iteration.number).to eq("2")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("guide")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/DGuide 99999.2" do
      subject { "ISO/DGuide 99999.2" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO DGuide 99999.2" }
      let(:urn) { "urn:iso:std:iso:guide:99999:stage-40.00.v2" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("99999")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("dguide")
      end

      it "parses iteration" do
        expect(parsed.stage_iteration.number).to eq("2")
      end

      it "normalizes format" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("guide")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test language variations
  context "languages" do
    describe "ISO/IEC Guide 2:2004(E/F/R)" do
      subject { "ISO/IEC Guide 2:2004(E/F/R)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # V2 preserves original language format
      let(:normalized) do
        "ISO/IEC Guide 2:2004(E/F/R)"
      end
      let(:urn) { "urn:iso:std:iso-iec:guide:2:en,fr,ru" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2004")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[en fr ru])
      end

      it "normalizes language format" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("guide")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/Guide 73:2009(en)" do
      subject { "ISO/Guide 73:2009(en)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO Guide 73:2009(en)" }
      let(:urn) { "urn:iso:std:iso:guide:73:en" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("73")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2009")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[en])
      end

      it "normalizes format" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("guide")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end
end
