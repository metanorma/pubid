require "spec_helper"

RSpec.describe Pubid::Iso::Identifiers::Amendment do
  subject { described_class }


  # Test basic amendment identifiers
  context "basic amendment identifiers" do
    describe "ISO 10231:2003/Amd 1:2015" do
      subject { "ISO 10231:2003/Amd 1:2015" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:10231:amd:2015:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("10231")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2003")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2015")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 13688:2013/Amd 1:2021" do
      subject { "ISO 13688:2013/Amd 1:2021" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:13688:amd:2021:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("13688")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2013")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2021")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 123:1999/Amd 1" do
      subject { "ISO 123:1999/Amd 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:123:amd:1:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("123")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("1999")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 8601-1:2019/Amd 1" do
      subject { "ISO 8601-1:2019/Amd 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:8601:-1:amd:1:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("8601")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2019")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 8601-1:2019/Amd 1:2023" do
      subject { "ISO 8601-1:2019/Amd 1:2023" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:8601:-1:amd:2023:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("8601")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2019")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2023")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 8601-1:2019/Amd 1:2023(E)" do
      subject { "ISO 8601-1:2019/Amd 1:2023(E)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO 8601-1:2019/Amd 1:2023(en)" }
      let(:urn) { "urn:iso:std:iso:8601:-1:amd:2023:v1:en" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("8601")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2019")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2023")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[en])
      end

      it "normalizes language format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 8601-1:2019/Amd 1:2023(en)" do
      subject { "ISO 8601-1:2019/Amd 1:2023(en)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:8601:-1:amd:2023:v1:en" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("8601")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2019")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2023")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[en])
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test amendment with parts
  context "amendments with parts" do
    describe "ISO 19110:2005/Amd 1:2011" do
      subject { "ISO 19110:2005/Amd 1:2011" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:19110:amd:2011:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("19110")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2005")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2011")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 10993-4:2002/Amd 1:2006" do
      subject { "ISO 10993-4:2002/Amd 1:2006" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:10993:-4:amd:2006:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("10993")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("4")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2002")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2006")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test legacy format normalization
  context "legacy format normalization" do
    describe "ISO 105-B01:1994/AMD 1:1998" do
      subject { "ISO 105-B01:1994/AMD 1:1998" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # V2 preserves original format
      let(:normalized) do
        "ISO 105-B01:1994/AMD 1:1998"
      end
      let(:urn) { "urn:iso:std:iso:105:-B01:amd:1998:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("105")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("B01")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("1994")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("1998")
      end

      it "preserves format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 10993-4:2002/Amd.1:2006(E)" do
      subject { "ISO 10993-4:2002/Amd.1:2006(E)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO 10993-4:2002/Amd 1:2006(en)" }
      let(:urn) { "urn:iso:std:iso:10993:-4:amd:2006:v1:en" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("10993")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("4")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2002")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2006")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[en])
      end

      it "normalizes format and language" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("Amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test copublisher amendments
  context "copublisher amendments" do
    context "copublisher as IEC" do
      describe "ISO/IEC 14496-10:2020/CD Amd 1" do
        subject { "ISO/IEC 14496-10:2020/CD Amd 1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:14496:-10:CD:amd:1:v1" }

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
          expect(parsed.base.part.value).to eq("10")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("2020")
        end

        it "parses amendment number" do
          expect(parsed.number.value).to eq("1")
        end

        it "parses amendment date" do
          expect(parsed.date).to be_nil
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("cd")
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("amd")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO/IEC 8802-3:2021/Amd 7:2021" do
        subject { "ISO/IEC 8802-3:2021/Amd 7:2021" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:8802:-3:amd:2021:v7" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.base.publisher.copublisher.first).to eq("IEC")
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("8802")
        end

        it "parses base identifier part" do
          expect(parsed.base.part.value).to eq("3")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("2021")
        end

        it "parses amendment number" do
          expect(parsed.number.value).to eq("7")
        end

        it "parses amendment date" do
          expect(parsed.date.year).to eq("2021")
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("amd")
        end

        it "provides stage code" do
          expect(parsed.typed_stage.stage_code).to eq("published")
        end

        it "provides typed_stage with abbreviation" do
          expect(parsed.typed_stage.abbr.first).to eq("Amd")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "triple copublisher as IEC/IEEE" do
      describe "ISO/IEC/IEEE 8802-3:2021/FDAmd 11" do
        subject { "ISO/IEC/IEEE 8802-3:2021/FDAmd 11" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        # Draft amendment renders the canonical short form (FDAM), matching v1.
        let(:normalized) do
          "ISO/IEC/IEEE 8802-3:2021/FDAM 11"
        end
        let(:urn) { "urn:iso:std:iso-iec-ieee:8802:-3:FDAM:amd:11:v1" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses copublishers" do
          expect(parsed.base.copublishers.map(&:body)).to eq(%w[IEC
                                                                           IEEE])
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("8802")
        end

        it "parses base identifier part" do
          expect(parsed.base.part.value).to eq("3")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("2021")
        end

        it "parses amendment number" do
          expect(parsed.number.value).to eq("11")
        end

        it "parses amendment date" do
          expect(parsed.date).to be_nil
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("fdamd")
        end

        it "normalizes format" do
          expect(parsed.to_s(with_edition: true)).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("amd")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO/IEC/IEEE 8802-22:2015/Amd 2:2017(en)" do
        subject { "ISO/IEC/IEEE 8802-22:2015/Amd 2:2017(en)" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec-ieee:8802:-22:amd:2017:v2:en" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses copublishers" do
          expect(parsed.base.copublishers.map(&:body)).to eq(%w[IEC
                                                                           IEEE])
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("8802")
        end

        it "parses base identifier part" do
          expect(parsed.base.part.value).to eq("22")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("2015")
        end

        it "parses amendment number" do
          expect(parsed.number.value).to eq("2")
        end

        it "parses amendment date" do
          expect(parsed.date.year).to eq("2017")
        end

        it "parses languages" do
          expect(parsed.languages.map(&:code)).to eq(%w[en])
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("amd")
        end

        it "provides stage code" do
          expect(parsed.typed_stage.stage_code).to eq("published")
        end

        it "provides typed_stage with abbreviation" do
          expect(parsed.typed_stage.abbr.first).to eq("Amd")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO/IEC/IEEE 8802-22.2:2015/Amd.2:2017(E)" do
        subject { "ISO/IEC/IEEE 8802-22.2:2015/Amd.2:2017(E)" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        # update_codes normalizes 8802-22.2 to 8802-22
        let(:normalized) { "ISO/IEC/IEEE 8802-22:2015/Amd 2:2017(en)" }
        let(:urn) { "urn:iso:std:iso-iec-ieee:8802:-22:amd:2017:v2:en" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses copublishers" do
          expect(parsed.base.copublishers.map(&:body)).to eq(%w[IEC
                                                                           IEEE])
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("8802")
        end

        it "parses base identifier part" do
          expect(parsed.base.part.value).to eq("22")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("2015")
        end

        it "parses amendment number" do
          expect(parsed.number.value).to eq("2")
        end

        it "parses amendment date" do
          expect(parsed.date.year).to eq("2017")
        end

        it "parses languages" do
          expect(parsed.languages.map(&:code)).to eq(%w[en])
        end

        it "normalizes format and language" do
          expect(parsed.to_s(with_edition: true)).to eq(normalized)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("amd")
        end

        it "provides stage code" do
          expect(parsed.typed_stage.stage_code).to eq("published")
        end

        it "provides typed_stage with abbreviation" do
          expect(parsed.typed_stage.abbr.first).to eq("Amd")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end
  end

  # Test amendment stages
  context "amendment stages" do
    context "preliminary" do
      describe "ISO 10791-6:2014/PWI Amd 1" do
        subject { "ISO 10791-6:2014/PWI Amd 1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:10791:-6:stage-00.00:amd:1:v1" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("10791")
        end

        it "parses base identifier part" do
          expect(parsed.base.part.value).to eq("6")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("2014")
        end

        it "parses amendment number" do
          expect(parsed.number.value).to eq("1")
        end

        it "parses amendment date" do
          expect(parsed.date).to be_nil
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("proposal")
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("amd")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "preparatory" do
      describe "ISO 11855-5:2021/AWI Amd 1" do
        subject { "ISO 11855-5:2021/AWI Amd 1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:11855:-5:stage-10.99:amd:1:v1" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("11855")
        end

        it "parses base identifier part" do
          expect(parsed.base.part.value).to eq("5")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("2021")
        end

        it "parses amendment number" do
          expect(parsed.number.value).to eq("1")
        end

        it "parses amendment date" do
          expect(parsed.date).to be_nil
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("preliminary")
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("amd")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      describe "ISO 20138-2:2019/WD Amd 1" do
        subject { "ISO 20138-2:2019/WD Amd 1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:20138:-2:stage-20.20:amd:1:v1" }

        it "parses publisher" do
          expect(parsed.base.publisher.publisher).to eq("ISO")
        end

        it "parses base identifier number" do
          expect(parsed.base.number.value).to eq("20138")
        end

        it "parses base identifier part" do
          expect(parsed.base.part.value).to eq("2")
        end

        it "parses base identifier date" do
          expect(parsed.base.date.year).to eq("2019")
        end

        it "parses amendment number" do
          expect(parsed.number.value).to eq("1")
        end

        it "parses amendment date" do
          expect(parsed.date).to be_nil
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("working_draft")
        end

        it "round-trips" do
          expect(parsed.to_s(with_edition: true)).to eq(subject)
        end

        it "provides type code" do
          expect(parsed.typed_stage.type_code).to eq("amd")
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end
  end

  # Test enquiry stages
  context "enquiry stages" do
    describe "ISO 10993-18:2020/DAmd 1" do
      subject { "ISO 10993-18:2020/DAmd 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # Draft amendment renders the canonical short form (DAM), matching v1.
      let(:normalized) do
        "ISO 10993-18:2020/DAM 1"
      end
      let(:urn) { "urn:iso:std:iso:10993:-18:stage-40.00:amd:1:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("10993")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("18")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2020")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("damd")
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 15874-3:2013/DAM 2" do
      subject { "ISO 15874-3:2013/DAM 2" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:15874:-3:stage-40.00:amd:2:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("15874")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("3")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2013")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("damd")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 15874-3:2013/DAM 2:2020(E)" do
      subject { "ISO 15874-3:2013/DAM 2:2020(E)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO 15874-3:2013/DAM 2:2020(en)" }
      let(:urn) { "urn:iso:std:iso:15874:-3:stage-40.00:amd:2020:v2:en" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("15874")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("3")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2013")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2020")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[en])
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("damd")
      end

      it "normalizes language format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 7207-2:2011/DAM 2:2019(F)" do
      subject { "ISO 7207-2:2011/DAM 2:2019(F)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO 7207-2:2011/DAM 2:2019(fr)" }
      let(:urn) { "urn:iso:std:iso:7207:-2:stage-40.00:amd:2019:v2:fr" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("7207")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("2")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2011")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2019")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[fr])
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("damd")
      end

      it "normalizes language format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test approval stages
  context "approval stages" do
    describe "ISO 19110:2005/FDAM 1" do
      subject { "ISO 19110:2005/FDAM 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:19110:FDAM:amd:1:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("19110")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2005")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("fdamd")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 4254-1:2005/FDAM 1:2007" do
      subject { "ISO 4254-1:2005/FDAM 1:2007" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:4254:-1:FDAM:amd:2007:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("4254")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2005")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2007")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("fdamd")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 3245:2015/FDAmd 1" do
      subject { "ISO 3245:2015/FDAmd 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # Draft amendment renders the canonical short form (FDAM), matching v1.
      let(:normalized) do
        "ISO 3245:2015/FDAM 1"
      end
      let(:urn) { "urn:iso:std:iso:3245:FDAM:amd:1:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("3245")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2015")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("fdamd")
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test publication/proof stages
  context "proof stages" do
    describe "ISO 18362:2016/PRF Amd 1" do
      subject { "ISO 18362:2016/PRF Amd 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:18362:stage-50.00:amd:1:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("18362")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2016")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("prf")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC 14496-10:2014/FPDAM 1(en)" do
      subject { "ISO/IEC 14496-10:2014/FPDAM 1(en)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # V2 preserves original format
      let(:normalized) do
        "ISO/IEC 14496-10:2014/FPDAM 1(en)"
      end
      let(:urn) { "urn:iso:std:iso-iec:14496:-10:FDAM:amd:1:v1:en" }

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
        expect(parsed.base.part.value).to eq("10")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2014")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[en])
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("fdamd")
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test stage iterations
  context "stage iterations" do
    describe "ISO 17301-1:2016/NP Amd 1.2" do
      subject { "ISO 17301-1:2016/NP Amd 1.2" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:17301:-1:stage-10.00:amd:1:v1.2" }

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

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("proposal")
      end

      it "parses iteration" do
        expect(parsed.stage_iteration.number).to eq("2")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 17301-1:2016/NP Amd 1.2:2022" do
      subject { "ISO 17301-1:2016/NP Amd 1.2:2022" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:17301:-1:stage-10.00:amd:2022:v1.2" }

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

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2022")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("proposal")
      end

      it "parses iteration" do
        expect(parsed.stage_iteration.number).to eq("2")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 17301-1:2016/FDAM 1.3:2022" do
      subject { "ISO 17301-1:2016/FDAM 1.3:2022" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:17301:-1:FDAM.3:amd:2022:v1.3" }

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

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2022")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("fdamd")
      end

      it "parses iteration" do
        expect(parsed.stage_iteration.number).to eq("3")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test amendment with draft base identifiers
  context "draft base identifiers" do
    describe "ISO/IEC DIS 23008-1/DAM 2:2021(E)" do
      subject { "ISO/IEC DIS 23008-1/DAM 2:2021(E)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # V2 normalizes language code
      let(:normalized) do
        "ISO/IEC DIS 23008-1/DAM 2:2021(en)"
      end
      let(:urn) { "urn:iso:std:iso-iec:23008:-1:stage-40.00:amd:2021:v2:en" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("23008")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier stage" do
        expect(parsed.base.typed_stage.stage_code).to eq("dis")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2021")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[en])
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("damd")
      end

      it "normalizes language format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC DIS 23008-1/DAmd 2(en)" do
      subject { "ISO/IEC DIS 23008-1/DAmd 2(en)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # Draft amendment renders the canonical short form (DAM), matching v1.
      let(:normalized) do
        "ISO/IEC DIS 23008-1/DAM 2(en)"
      end
      let(:urn) { "urn:iso:std:iso-iec:23008:-1:stage-40.00:amd:2:v1:en" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("23008")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier stage" do
        expect(parsed.base.typed_stage.stage_code).to eq("dis")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[en])
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("damd")
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test editions
  context "editions" do
    describe "ISO 8601-1:2019/Amd 1:2023 ED1" do
      subject { "ISO 8601-1:2019/Amd 1:2023 ED1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:8601:-1:ed-1:amd:2023:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("8601")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2019")
      end

      it "parses edition" do
        expect(parsed.edition&.value).to eq("1")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2023")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 8601-1:2019/Amd 1:2023 ED1(en)" do
      subject { "ISO 8601-1:2019/Amd 1:2023 ED1(en)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:8601:-1:ed-1:amd:2023:v1:en" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("8601")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2019")
      end

      it "parses edition" do
        expect(parsed.edition&.value).to eq("1")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2023")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[en])
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 13688:2013/Amd 1:2021 ED1(en)" do
      subject { "ISO 13688:2013/Amd 1:2021 ED1(en)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:13688:ed-1:amd:2021:v1:en" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("13688")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2013")
      end

      it "parses edition" do
        expect(parsed.edition&.value).to eq("1")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2021")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[en])
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 13688 ED1/Amd 1:2021(en)" do
      subject { "ISO 13688 ED1/Amd 1:2021(en)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:13688:ed-1:amd:2021:v1:en" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("13688")
      end

      it "parses base identifier date" do
        expect(parsed.base.date).to be_nil
      end

      it "parses edition" do
        expect(parsed.base.edition&.value).to eq("1")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2021")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[en])
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC 8802-3:2021/Amd 7:2021 ED3" do
      subject { "ISO/IEC 8802-3:2021/Amd 7:2021 ED3" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:8802:-3:ed-3:amd:2021:v7" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("8802")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("3")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2021")
      end

      it "parses edition" do
        expect(parsed.edition&.value).to eq("3")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("7")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2021")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC/IEEE 8802-22:2015 ED1/Amd 2:2017(en)" do
      subject { "ISO/IEC/IEEE 8802-22:2015 ED1/Amd 2:2017(en)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec-ieee:8802:-22:ed-1:amd:2017:v2:en" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublishers" do
        expect(parsed.base.copublishers.map(&:body)).to eq(%w[IEC
                                                                         IEEE])
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("8802")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("22")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2015")
      end

      it "parses edition" do
        expect(parsed.base.edition&.value).to eq("1")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2017")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[en])
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 10993-4:2002/Amd.1:2006 ED2(E)" do
      subject { "ISO 10993-4:2002/Amd.1:2006 ED2(E)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO 10993-4:2002/Amd 1:2006 ED2(en)" }
      let(:urn) { "urn:iso:std:iso:10993:-4:ed-2:amd:2006:v1:en" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("10993")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("4")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2002")
      end

      it "parses edition" do
        expect(parsed.edition&.value).to eq("2")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2006")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[en])
      end

      it "normalizes format and language" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC 10646:2020/CD Amd 1 ED6" do
      subject { "ISO/IEC 10646:2020/CD Amd 1 ED6" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/IEC 10646:2020/CD Amd 1 ED6" }
      let(:urn) { "urn:iso:std:iso-iec:10646:ed-6:CD:amd:1:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("10646")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2020")
      end

      it "parses edition" do
        expect(parsed.edition&.value).to eq("6")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("cd")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 15002:2008/DAM 2:2020 ED2(F)" do
      subject { "ISO 15002:2008/DAM 2:2020 ED2(F)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO 15002:2008/DAM 2:2020 ED2(fr)" }
      let(:urn) { "urn:iso:std:iso:15002:ed-2:stage-40.00:amd:2020:v2:fr" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("15002")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2008")
      end

      it "parses edition" do
        expect(parsed.edition&.value).to eq("2")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("2")
      end

      it "parses amendment date" do
        expect(parsed.date.year).to eq("2020")
      end

      it "parses languages" do
        expect(parsed.languages.map(&:code)).to eq(%w[fr])
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("damd")
      end

      it "normalizes language format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO 11137-2:2013/FDAmd 1 ED3" do
      subject { "ISO 11137-2:2013/FDAmd 1 ED3" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # Draft amendment renders the canonical short form (FDAM), matching v1.
      let(:normalized) do
        "ISO 11137-2:2013/FDAM 1 ED3"
      end
      let(:urn) { "urn:iso:std:iso:11137:-2:ed-3:FDAM:amd:1:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("11137")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("2")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2013")
      end

      it "parses edition" do
        expect(parsed.edition&.value).to eq("3")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("fdamd")
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC 14496-30:2018/FDAmd 1 ED2" do
      subject { "ISO/IEC 14496-30:2018/FDAmd 1 ED2" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # Draft amendment renders the canonical short form (FDAM), matching v1.
      let(:normalized) do
        "ISO/IEC 14496-30:2018/FDAM 1 ED2"
      end
      let(:urn) { "urn:iso:std:iso-iec:14496:-30:ed-2:FDAM:amd:1:v1" }

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
        expect(parsed.base.part.value).to eq("30")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2018")
      end

      it "parses edition" do
        expect(parsed.edition&.value).to eq("2")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("fdamd")
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test additional enquiry/committee stages
  context "additional amendment stages" do
    describe "ISO/IEC FDIS 23008-1/WD Amd 1" do
      subject { "ISO/IEC FDIS 23008-1/WD Amd 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:23008:-1:stage-20.20:amd:1:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("23008")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("1")
      end

      it "parses base identifier stage" do
        expect(parsed.base.typed_stage.stage_code).to eq("fdis")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("working_draft")
      end

      it "round-trips" do
        expect(parsed.to_s(with_edition: true)).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC FDIS 23090-14/DAmd 1" do
      subject { "ISO/IEC FDIS 23090-14/DAmd 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # Draft amendment renders the canonical short form (DAM), matching v1.
      let(:normalized) do
        "ISO/IEC FDIS 23090-14/DAM 1"
      end
      let(:urn) { "urn:iso:std:iso-iec:23090:-14:stage-40.00:amd:1:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("23090")
      end

      it "parses base identifier part" do
        expect(parsed.base.part.value).to eq("14")
      end

      it "parses base identifier stage" do
        expect(parsed.base.typed_stage.stage_code).to eq("fdis")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("damd")
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC 27006:2015/PDAM 1" do
      subject { "ISO/IEC 27006:2015/PDAM 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # V2 preserves original format
      let(:normalized) do
        "ISO/IEC 27006:2015/PDAM 1"
      end
      let(:urn) { "urn:iso:std:iso-iec:27006:CD:amd:1:v1" }

      it "parses publisher" do
        expect(parsed.base.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.base.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("27006")
      end

      it "parses base identifier date" do
        expect(parsed.base.date.year).to eq("2015")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("cd")
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC 14496-12:2012/PDAM 4 ED4" do
      subject { "ISO/IEC 14496-12:2012/PDAM 4 ED4" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # V2 preserves original format
      let(:normalized) do
        "ISO/IEC 14496-12:2012/PDAM 4 ED4"
      end
      let(:urn) { "urn:iso:std:iso-iec:14496:-12:ed-4:CD:amd:4:v1" }

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
        expect(parsed.base.date.year).to eq("2012")
      end

      it "parses edition" do
        expect(parsed.edition&.value).to eq("4")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("4")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("cd")
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test legacy stage variations
  context "legacy stage variations" do
    describe "ISO/IEC 14496-12:2012/PDAM 4" do
      subject { "ISO/IEC 14496-12:2012/PDAM 4" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      # V2 preserves original format
      let(:normalized) do
        "ISO/IEC 14496-12:2012/PDAM 4"
      end
      let(:urn) { "urn:iso:std:iso-iec:14496:-12:CD:amd:4:v1" }

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
        expect(parsed.base.date.year).to eq("2012")
      end

      it "parses amendment number" do
        expect(parsed.number.value).to eq("4")
      end

      it "parses amendment date" do
        expect(parsed.date).to be_nil
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("cd")
      end

      it "normalizes format" do
        expect(parsed.to_s(with_edition: true)).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("amd")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end
end
