require "spec_helper"

RSpec.describe Pubid::Iso::Identifiers::TechnicalReport do
  subject { described_class }


  # Test normal dated technical report
  context "parse normal dated technical report" do
    # ISO/TR 10771-2:2008
    describe "ISO/TR 10771-2:2008" do
      subject { "ISO/TR 10771-2:2008" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:tr:10771:-2" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("10771")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("2")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2008")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("tr")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("TR")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test normal undated technical report
  context "parse normal undated technical report" do
    # ISO/TR 10303-307
    describe "ISO/TR 10303-307" do
      subject { "ISO/TR 10303-307" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:tr:10303:-307" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("10303")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("307")
      end

      it "parses date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("tr")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("TR")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # ISO/IEC TR 10000-1
    describe "ISO/IEC TR 10000-1" do
      subject { "ISO/IEC TR 10000-1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:tr:10000:-1" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("10000")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("1")
      end

      it "parses date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("tr")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test technical report with complex subparts
  context "parse technical report with complex subparts" do
    # ISO/IEC TR 29110-3-4
    describe "ISO/IEC TR 29110-3-4" do
      subject { "ISO/IEC TR 29110-3-4" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:tr:29110:-3-4" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("29110")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("3")
      end

      it "parses subpart" do
        expect(parsed.subpart.value).to eq("4")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # ISO/IEC TR 29110-5-1-4
    describe "ISO/IEC TR 29110-5-1-4" do
      subject { "ISO/IEC TR 29110-5-1-4" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:tr:29110:-5-1-4" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("29110")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("5")
      end

      it "parses subpart" do
        expect(parsed.subpart.value).to eq("1-4")
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
      # ISO/IEC TR 13818-5:2005
      describe "ISO/IEC TR 13818-5:2005" do
        subject { "ISO/IEC TR 13818-5:2005" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:tr:13818:-5" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("13818")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("5")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2005")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "copublisher as ASTM" do
      # ISO/ASTM TR 52906
      describe "ISO/ASTM TR 52906" do
        subject { "ISO/ASTM TR 52906" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-astm:tr:52906" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("ASTM")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("52906")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "copublisher as CIE" do
      # ISO/CIE TR 21783
      describe "ISO/CIE TR 21783" do
        subject { "ISO/CIE TR 21783" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-cie:tr:21783" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("CIE")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("21783")
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
    # ISO/IEC/TR 30148 (extra slash)
    describe "ISO/IEC/TR 30148" do
      subject { "ISO/IEC/TR 30148" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/IEC TR 30148" }
      let(:urn) { "urn:iso:std:iso-iec:tr:30148" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("30148")
      end

      it "normalizes format" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # ISO TR 16401-2 (missing slash)
    describe "ISO TR 16401-2" do
      subject { "ISO TR 16401-2" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/TR 16401-2" }
      let(:urn) { "urn:iso:std:iso:tr:16401:-2" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("16401")
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

    # ISO/TR27809:2007 (missing space)
    describe "ISO/TR27809:2007" do
      subject { "ISO/TR27809:2007" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/TR 27809:2007" }
      let(:urn) { "urn:iso:std:iso:tr:27809" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("27809")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2007")
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
      # ISO/NP TR 11111 (example from comments)
      describe "ISO/NP TR 11111" do
        subject { "ISO/NP TR 11111" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:tr:11111:stage-10.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("11111")
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
      # ISO/WD TR 23642
      describe "ISO/WD TR 23642" do
        subject { "ISO/WD TR 23642" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:tr:23642:WD" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("23642")
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

    context "committee" do
      # ISO/CD TR 12786.2 (example from comments)
      describe "ISO/CD TR 12786.2" do
        subject { "ISO/CD TR 12786.2" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:tr:12786:CD.2" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("12786")
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

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "enquiry" do
      # ISO/IEC DTR 27563
      describe "ISO/IEC DTR 27563" do
        subject { "ISO/IEC DTR 27563" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:tr:27563:stage-40.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("27563")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("draft")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      # ISO/ASTM DTR 52905
      describe "ISO/ASTM DTR 52905" do
        subject { "ISO/ASTM DTR 52905" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-astm:tr:52905:stage-40.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("ASTM")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("52905")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("draft")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "approval" do
      # ISO/IEC/IEEE FDTR 17301-1-1:2016(en) (example from comments)
      describe "ISO/IEC/IEEE FDTR 17301-1-1:2016(en)" do
        subject { "ISO/IEC/IEEE FDTR 17301-1-1:2016(en)" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec-ieee:tr:17301:-1-1:stage-50.00:en" }

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
          expect(parsed.typed_stage.stage_code).to eq("final_draft")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end
    end

    context "publication" do
      # ISO/PRF TR 14799-1
      describe "ISO/PRF TR 14799-1" do
        subject { "ISO/PRF TR 14799-1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:tr:14799:-1:stage-50.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("14799")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("1")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("prf")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      # ISO/PRF TR 23249
      describe "ISO/PRF TR 23249" do
        subject { "ISO/PRF TR 23249" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:tr:23249:stage-50.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("23249")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("prf")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      # ISO/PRF TR 31700-2
      describe "ISO/PRF TR 31700-2" do
        subject { "ISO/PRF TR 31700-2" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:tr:31700:-2:stage-50.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("31700")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("2")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("prf")
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
    # ISO/CIE DTR 21783.2
    describe "ISO/CIE DTR 21783.2" do
      subject { "ISO/CIE DTR 21783.2" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-cie:tr:21783:stage-40.00.v2" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("CIE")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("21783")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("draft")
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

    # ISO/CD TR 22260-1.2 (example from comments)
    describe "ISO/CD TR 22260-1.2" do
      subject { "ISO/CD TR 22260-1.2" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:tr:22260:-1:CD.2" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("22260")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("1")
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

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test legacy stages
  context "legacy stages" do
    # ISO/IEC PDTR 20943-5 (legacy PDTR harmonized to CD stage)
    describe "ISO/IEC PDTR 20943-5" do
      subject { "ISO/IEC PDTR 20943-5" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:tr:20943:-5:CD" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("20943")
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

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end
end
