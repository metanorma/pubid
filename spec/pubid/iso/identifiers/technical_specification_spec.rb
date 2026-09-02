require "spec_helper"

RSpec.describe Pubid::Iso::Identifiers::TechnicalSpecification do
  subject { described_class }


  # Test normal dated technical specification
  context "parse normal dated technical specification" do
    # ISO/TS 10832:2009
    describe "ISO/TS 10832:2009" do
      subject { "ISO/TS 10832:2009" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:ts:10832" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("10832")
      end

      it "parses part" do
        expect(parsed.part&.value).to be_nil
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2009")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("ts")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("TS")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test normal undated technical specification
  context "parse normal undated technical specification" do
    # ISO/TS 16791
    describe "ISO/TS 16791" do
      subject { "ISO/TS 16791" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:ts:16791" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("16791")
      end

      it "parses part" do
        expect(parsed.part&.value).to be_nil
      end

      it "parses date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("ts")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("TS")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test technical specification with parts
  context "parse technical specification with parts" do
    # ISO/TS 10303-1751:2014
    describe "ISO/TS 10303-1751:2014" do
      subject { "ISO/TS 10303-1751:2014" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/TS 10303-1751:2014" }
      let(:urn) { "urn:iso:std:iso:ts:10303:-1751" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("10303")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("1751")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2014")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # ISO/IEC TS 17021-2:2012
    describe "ISO/IEC TS 17021-2:2012" do
      subject { "ISO/IEC TS 17021-2:2012" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:ts:17021:-2" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("17021")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("2")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2012")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test copublishers
  context "copublishers" do
    context "copublisher as IEC" do
      # ISO/IEC TS 17961:2013
      describe "ISO/IEC TS 17961:2013" do
        subject { "ISO/IEC TS 17961:2013" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:ts:17961" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("17961")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2013")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end
  end

  # Test aberrations
  context "aberrations" do
    # ISO/IEC/TS 17021-2 (extra slash)
    describe "ISO/IEC/TS 17021-2" do
      subject { "ISO/IEC/TS 17021-2" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/IEC TS 17021-2" }
      let(:urn) { "urn:iso:std:iso-iec:ts:17021:-2" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("17021")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("2")
      end

      it "normalizes format" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # ISO/TS 10303- 1751:2014 (extra space)
    describe "ISO/TS 10303- 1751:2014" do
      subject { "ISO/TS 10303- 1751:2014" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/TS 10303-1751:2014" }
      let(:urn) { "urn:iso:std:iso:ts:10303:-1751" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("10303")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("1751")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2014")
      end

      it "normalizes format" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test stages
  context "stages" do
    context "proposal" do
      # ISO/NP TS 20594-1
      describe "ISO/NP TS 20594-1" do
        subject { "ISO/NP TS 20594-1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:ts:20594:-1:stage-10.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("20594")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("1")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("np")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "preparatory" do
      # ISO/IEC WD TS 25025
      describe "ISO/IEC WD TS 25025" do
        subject { "ISO/IEC WD TS 25025" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:ts:25025:WD" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("25025")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("wd")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "enquiry" do
      # ISO/DTS 18759
      describe "ISO/DTS 18759" do
        subject { "ISO/DTS 18759" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:ts:18759:DTS" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("18759")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("dts")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      # ISO/IEC DTS 5723
      describe "ISO/IEC DTS 5723" do
        subject { "ISO/IEC DTS 5723" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:ts:5723:DTS" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("5723")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("dts")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end
  end

  # Test stage with iteration
  context "stage with iteration" do
    # ISO/DTS 21328.4
    describe "ISO/DTS 21328.4" do
      subject { "ISO/DTS 21328.4" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:ts:21328:DTS.4" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("21328")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("dts")
      end

      it "parses iteration" do
        expect(parsed.stage_iteration.number).to eq("4")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # ISO/IEC DTS 25052-1.2
    describe "ISO/IEC DTS 25052-1.2" do
      subject { "ISO/IEC DTS 25052-1.2" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:ts:25052:-1:DTS.2" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("25052")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("1")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("dts")
      end

      it "parses iteration" do
        expect(parsed.stage_iteration.number).to eq("2")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test legacy stages
  context "legacy stages" do
    # ISO/IEC PDTS 19583-24
    describe "ISO/IEC PDTS 19583-24" do
      subject { "ISO/IEC PDTS 19583-24" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:ts:19583:-24:CDTS" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("19583")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("24")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("cd")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # ISO/IEC PDTS 27008
    describe "ISO/IEC PDTS 27008" do
      subject { "ISO/IEC PDTS 27008" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:ts:27008:CDTS" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("27008")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("cd")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test triple copublishers with languages
  context "triple copublishers with languages" do
    # ISO/IEC/IEEE DTS 17301-1-1:2016(en)
    describe "ISO/IEC/IEEE DTS 17301-1-1:2016(en)" do
      subject { "ISO/IEC/IEEE DTS 17301-1-1:2016(en)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec-ieee:ts:17301:-1-1:DTS:en" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublishers" do
        expect(parsed.copublishers.map(&:body)).to eq(%w[IEC IEEE])
      end

      it "parses number" do
        expect(parsed.number.value).to eq("17301")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("1")
      end

      it "parses subpart" do
        expect(parsed.subpart.value).to eq("1")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2016")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("dts")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end
end
