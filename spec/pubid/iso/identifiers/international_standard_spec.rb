require "spec_helper"

RSpec.describe Pubid::Iso::Identifiers::InternationalStandard do
  subject { described_class }


  # Test normal identifier dated
  context "parse normal identifier dated" do
    # ISO 19135:2025
    describe "ISO 19135:2025" do
      subject { "ISO 19135:2025" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:19135" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("19135")
      end

      it "parses part" do
        expect(parsed.part&.value).to be_nil
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2025")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("is")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation of blank for :is" do
        expect(parsed.typed_stage.abbr.first).to eq("")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test normal identifier undated
  context "parse normal identifier undated" do
    # ISO 4
    describe "ISO 4" do
      subject { "ISO 4" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:4" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("4")
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
        expect(parsed.typed_stage.type_code).to eq("is")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation of blank for :is" do
        expect(parsed.typed_stage.abbr.first).to eq("")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test normal identifier with part
  context "parse normal identifier with part" do
    # ISO 8601-1:2019
    describe "ISO 8601-1:2019" do
      subject { "ISO 8601-1:2019" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:8601:-1" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("8601")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("1")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2019")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("is")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation of blank for :is" do
        expect(parsed.typed_stage.abbr.first).to eq("")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  context "parse legacy parts" do
    # Test legacy parts
    # Dated legacy part
    # ISO 31/0-1974
    describe "ISO 31/0-1974" do
      subject { "ISO 31/0-1974" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:31:-0" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("31")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("0")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("1974")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq("ISO 31-0:1974")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # Undated legacy part
    # ISO 5843/6
    describe "ISO 5843/6" do
      subject { "ISO 5843/6" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:5843:-6" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("5843")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("6")
      end

      it "parses date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq("ISO 5843-6")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # Alphabetical part
    # ISO 105-C06:2010
    describe "ISO 105-C06:2010" do
      subject { "ISO 105-C06:2010" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:105:-C06" }
      # it_behaves_like "converts urn to pubid", "ISO 105-C06"

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("105")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("C06")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2010")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("is")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation of blank for :is" do
        expect(parsed.typed_stage.abbr.first).to eq("")
      end
    end
  end

  # Test edition
  context "parse identifiers with edition" do
    # Assume no edition when no number specified
    describe "ISO 22610:2006 Ed" do
      subject { "ISO 22610:2006 Ed" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:pubid) { "ISO 22610:2006" }
      let(:undated) { "ISO 22610" }
      let(:urn) { "urn:iso:std:iso:22610" }

      it "parses edition" do
        expect(parsed.edition&.value).to be_nil
      end

      it "generates clean pubid" do
        expect(parsed.to_s).to eq(pubid)
      end

      it "generates pubid with edition" do
        expect(parsed.to_s(with_edition: true)).to eq(pubid)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end

      it "generates urn to undated pubid" do
        expect(Pubid::Iso.parse_urn(urn).to_s(with_edition: true)).to eq(undated)
      end
    end

    describe "ISO 22610:2006 Ed 1" do
      subject { "ISO 22610:2006 Ed 1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:pubid) { "ISO 22610:2006" }
      let(:pubid_with_edition) { "ISO 22610:2006 ED1" }
      let(:undated_with_edition) { "ISO 22610 ED1" }
      let(:urn) { "urn:iso:std:iso:22610:ed-1" }

      it "parses edition" do
        expect(parsed.edition&.value).to eq("1")
      end

      it "generates clean pubid" do
        expect(parsed.to_s).to eq(pubid)
      end

      it "generates pubid with edition" do
        expect(parsed.to_s(with_edition: true)).to eq(pubid_with_edition)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end

      it "generates urn to undated pubid" do
        expect(Pubid::Iso.parse_urn(urn).to_s(with_edition: true)).to eq(undated_with_edition)
      end
    end

    describe "ISO 11553-1 Ed.2" do
      subject { "ISO 11553-1 Ed.2" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:pubid) { "ISO 11553-1" }
      let(:pubid_with_edition) { "ISO 11553-1 ED2" }
      let(:urn) { "urn:iso:std:iso:11553:-1:ed-2" }

      it "parses edition" do
        expect(parsed.edition&.value).to eq("2")
      end

      it "generates clean pubid" do
        expect(parsed.to_s).to eq(pubid)
      end

      it "generates pubid with edition" do
        expect(parsed.to_s(with_edition: true)).to eq(pubid_with_edition)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end

      it "generates urn to pubid" do
        expect(Pubid::Iso.parse_urn(urn).to_s(with_edition: true)).to eq(pubid_with_edition)
      end
    end

    describe "ISO/IEC 30142 ED1" do
      subject { "ISO/IEC 30142 ED1" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:pubid) { "ISO/IEC 30142" }
      let(:pubid_with_edition) { "ISO/IEC 30142 ED1" }
      let(:urn) { "urn:iso:std:iso-iec:30142:ed-1" }

      it "parses edition" do
        expect(parsed.edition&.value).to eq("1")
      end

      it "generates clean pubid" do
        expect(parsed.to_s).to eq(pubid)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end

      it "generates urn to pubid" do
        expect(Pubid::Iso.parse_urn(urn).to_s(with_edition: true)).to eq(pubid_with_edition)
      end
    end
  end

  # Test normal identifier with subpart
  context "parse normal identifier with subpart" do
    # ISO 80601-2-61:2019
    describe "ISO 80601-2-61:2019" do
      subject { "ISO 80601-2-61:2019" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:80601:-2-61" }
      let(:undated) { Pubid::Iso.parse("ISO 80601-2-61") }

      it "parses part" do
        expect(parsed.part.value).to eq("2")
      end

      it "parses subpart" do
        expect(parsed.subpart.value).to eq("61")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2019")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end

      it "generates urn to undated pubid" do
        expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(undated.to_s)
      end
    end
  end

  # Test normal identifier with sub-subpart
  context "parse normal identifier with sub-subpart" do
    # ISO/IEC 29110-5-1-1:2025
    describe "ISO/IEC 29110-5-1-1:2025" do
      subject { "ISO/IEC 29110-5-1-1:2025" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso-iec:29110:-5-1-1" }
      let(:undated) { Pubid::Iso.parse("ISO/IEC 29110-5-1-1") }

      it "parses part" do
        expect(parsed.part.value).to eq("5")
      end

      it "parses subpart" do
        expect(parsed.subpart.value).to eq("1-1")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2025")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end

      it "generates urn to undated pubid" do
        expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(undated.to_s)
      end
    end
  end

  context "copublishers" do
    # Test aberrations
    context "abberations" do
      # Extra space between co-publishers
      describe "ISO /IEC 17030:2003" do
        subject { "ISO /IEC 17030:2003" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:pubid) { "ISO/IEC 17030:2003" }
        let(:urn) { "urn:iso:std:iso-iec:17030" }
        let(:undated) { Pubid::Iso.parse("ISO/IEC 17030") }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("17030")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2003")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(pubid)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end

        it "generates urn to undated pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(undated.to_s)
        end
      end

      # Unicode hyphen
      context "parses Unicode hyphen" do
        describe "U+2010" do
          subject { "ISO/IEC 80079‑34:2020" }

          let(:pubid) { "ISO/IEC 80079-34:2020" }

          it "round-trips" do
            expect(Pubid::Iso.parse(subject).to_s).to eq(pubid)
          end
        end

        context "U+2011" do
          subject { "ISO/IEC 80079‐34:2020" }

          let(:pubid) { "ISO/IEC 80079-34:2020" }

          it "round-trips" do
            expect(Pubid::Iso.parse(subject).to_s).to eq(pubid)
          end
        end
      end
    end

    # Test copublishers IEC
    context "copublisher as IEC" do
      # ISO/IEC 10164-22:2000
      describe "ISO/IEC 10164-22:2000" do
        subject { "ISO/IEC 10164-22:2000" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-iec:10164:-22" }
        let(:undated) { Pubid::Iso.parse("ISO/IEC 10164-22") }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEC")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("10164")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("22")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2000")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end

        it "generates urn to undated pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(undated.to_s)
        end
      end
    end

    # Test copublishers IEEE
    context "copublisher as IEEE" do
      describe "ISO/IEEE 11073-20601:2010" do
        subject { "ISO/IEEE 11073-20601:2010" }

        let(:urn) { "urn:iso:std:iso-ieee:11073:-20601" }
        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:undated) { Pubid::Iso.parse("ISO/IEEE 11073-20601") }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("IEEE")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("11073")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("20601")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2010")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end

        it "generates urn to undated pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(undated.to_s)
        end
      end
    end

    # Test copublishers IEC/IEEE
    context "copublisher as IEC/IEEE" do
      describe "ISO/IEC/IEEE 26512" do
        subject { "ISO/IEC/IEEE 26512" }

        # RFC 5141 only has iso-iec and iso-ieee, not iso-iec-ieee
        # iso-iec-ieee is an addition
        let(:urn) { "urn:iso:std:iso-iec-ieee:26512" }
        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:undated) { Pubid::Iso.parse("ISO/IEC/IEEE 26512") }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublishers" do
          expect(parsed.copublishers.map(&:body)).to eq(%w[IEC IEEE])
        end

        it "parses number" do
          expect(parsed.number.value).to eq("26512")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end

        it "generates urn to undated pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(undated.to_s)
        end
      end
    end

    # TODO: Move to IEEE parser
    # context "IEEE/ISO/IEC 8802-1Q-2020" do
    #   let(:original) { "IEEE/ISO/IEC 8802-1Q-2020" }
    #   let(:pubid) { "IEEE/ISO/IEC 8802-1Q:2020" }
    #   let(:urn) { "urn:iso:std:ieee-iec-iso:8802:-1Q" }

    #   it_behaves_like "converts pubid to pubid"
    #   it_behaves_like "converts pubid to urn"
    #   it_behaves_like "converts urn to pubid", "IEEE/IEC/ISO 8802-1Q"
    # end

    # Test copublishers CIE
    context "copublisher as CIE" do
      # ISO/CIE 11664-1:2019
      describe "ISO/CIE 11664-1:2019" do
        subject { "ISO/CIE 11664-1:2019" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-cie:11664:-1" }
        let(:undated) { Pubid::Iso.parse("ISO/CIE 11664-1") }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("CIE")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("11664")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("1")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2019")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end

        it "generates urn to undated pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(undated.to_s)
        end
      end
    end

    # Test copublishers HL7
    context "copublisher as HL7" do
      describe "ISO/HL7 27953-2:2011" do
        subject { "ISO/HL7 27953-2:2011" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-hl7:27953:-2" }
        let(:undated) { Pubid::Iso.parse("ISO/HL7 27953-2") }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("HL7")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("27953")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("2")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2011")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end

        it "generates urn to undated pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(undated.to_s)
        end
      end
    end

    # Test copublishers SAE
    context "copublisher as SAE" do
      # ISO/SAE 21434:2021
      describe "ISO/SAE 21434:2021" do
        subject { "ISO/SAE 21434:2021" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-sae:21434" }
        let(:undated) { Pubid::Iso.parse("ISO/SAE 21434") }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("SAE")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("21434")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2021")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end

        it "generates urn to undated pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(undated.to_s)
        end
      end
    end

    # Test copublishers OECD
    context "copublisher as OECD" do
      # ISO/OECD 789-10:2006
      describe "ISO/OECD 789-10:2006" do
        subject { "ISO/OECD 789-10:2006" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        # RFC 5141 does not contain iso-oecd
        let(:urn) { "urn:iso:std:iso-oecd:789:-10" }
        let(:undated) { Pubid::Iso.parse("ISO/OECD 789-10") }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("OECD")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("789")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("10")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2006")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end

        it "generates urn to undated pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(undated.to_s)
        end
      end
    end

    # Test copublishers ASTM
    context "copublisher as ASTM" do
      # ISO/ASTM 52901:2017
      describe "ISO/ASTM 52901:2017" do
        subject { "ISO/ASTM 52901:2017" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-astm:52901" }
        let(:undated) { Pubid::Iso.parse("ISO/ASTM 52901") }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("ASTM")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("52901")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2017")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end

        it "generates urn to undated pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(undated.to_s)
        end
      end
    end

    # Test copublisher UNDP
    context "copublisher as UNDP" do
      # ISO/UNDP 53001:2025

      describe "ISO/UNDP 53001:2025" do
        subject { "ISO/UNDP 53001:2025" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:pubid) { "ISO/UNDP 53001:2025" }
        let(:urn) { "urn:iso:std:iso-undp:53001" }
        let(:undated) { Pubid::Iso.parse("ISO/UNDP 53001") }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("UNDP")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("53001")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2025")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end

        it "generates urn to undated pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(undated.to_s)
        end
      end
    end

    # TODO: Move to PAS
    #   context "ISO/UNDP PAS 53002" do
    #   let(:pubid) { "ISO/UNDP PAS 53002" }
    #   let(:urn) { "urn:iso:std:iso-undp:pas:53002" }

    #   it_behaves_like "converts pubid to pubid"
    #   it_behaves_like "converts pubid to urn"
    #   it_behaves_like "converts urn to pubid", "ISO/UNDP PAS 53002"
    # end
  end

  # Test stages
  context "stages" do
    # Test stage without iteration
    context "stage without iteration" do
      context "preliminary" do
        # ISO/PWI 19171
        describe "ISO/PWI 19171" do
          subject { "ISO/PWI 19171" }

          let(:parsed) { Pubid::Iso.parse(subject) }
          let(:urn) { "urn:iso:std:iso:19171:stage-00.00" }

          it "parses publisher" do
            expect(parsed.publisher.publisher).to eq("ISO")
          end

          it "parses number" do
            expect(parsed.number.value).to eq("19171")
          end

          it "parses stage" do
            expect(parsed.typed_stage.stage_code).to eq("pwi")
          end

          it "round-trips" do
            expect(parsed.to_s).to eq(subject)
          end

          it "generates urn" do
            expect(parsed.to_urn).to eq(urn)
          end

          it "generates urn to pubid" do
            expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(subject)
          end
        end
      end

      context "proposal" do
        describe "ISO/NP 23219" do
          subject { "ISO/NP 23219" }

          let(:parsed) { Pubid::Iso.parse(subject) }
          let(:urn) { "urn:iso:std:iso:23219:stage-10.00" }

          it "parses publisher" do
            expect(parsed.publisher.publisher).to eq("ISO")
          end

          it "parses number" do
            expect(parsed.number.value).to eq("23219")
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

          it "generates urn to pubid" do
            expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(subject)
          end
        end

        # Different stage abbreviation
        describe "ISO/NWIP 19144-4" do
          subject { "ISO/NWIP 19144-4" }

          let(:parsed) { Pubid::Iso.parse(subject) }
          let(:pubid) { "ISO/NP 19144-4" }
          let(:urn) { "urn:iso:std:iso:19144:-4:stage-10.00" }

          it "round-trips" do
            expect(Pubid::Iso.parse(subject).to_s).to eq(pubid)
          end

          it "generates urn" do
            expect(Pubid::Iso.parse(subject).to_urn).to eq(urn)
          end

          it "generates urn to pubid" do
            expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(pubid)
          end
        end
      end

      context "proposal/approved" do
        # ISO/CIE AWI 19476
        describe "ISO/CIE AWI 19476" do
          subject { "ISO/CIE AWI 19476" }

          let(:parsed) { Pubid::Iso.parse(subject) }
          let(:urn) { "urn:iso:std:iso-cie:19476:stage-10.99" }

          it "parses publisher" do
            expect(parsed.publisher.publisher).to eq("ISO")
          end

          it "parses copublisher" do
            expect(parsed.publisher.copublisher.first).to eq("CIE")
          end

          it "parses number" do
            expect(parsed.number.value).to eq("19476")
          end

          it "parses stage" do
            expect(parsed.typed_stage.stage_code).to eq("awi")
          end

          it "round-trips" do
            expect(parsed.to_s).to eq(subject)
          end

          it "generates urn" do
            expect(parsed.to_urn).to eq(urn)
          end

          it "generates urn to pubid" do
            expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(subject)
          end
        end
      end

      context "preparatory" do
        # ISO/IEC WD 23773-1
        describe "ISO/IEC WD 23773-1" do
          subject { "ISO/IEC WD 23773-1" }

          let(:parsed) { Pubid::Iso.parse(subject) }
          let(:urn) { "urn:iso:std:iso-iec:23773:-1:WD" }

          it "parses publisher" do
            expect(parsed.publisher.publisher).to eq("ISO")
          end

          it "parses copublisher" do
            expect(parsed.publisher.copublisher.first).to eq("IEC")
          end

          it "parses number" do
            expect(parsed.number.value).to eq("23773")
          end

          it "parses part" do
            expect(parsed.part.value).to eq("1")
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

          it "generates urn to pubid" do
            expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(subject)
          end
        end
      end

      context "committee" do
        # ISO/IEC CD 29110-5-1-1
        describe "ISO/IEC CD 29110-5-1-1" do
          subject { "ISO/IEC CD 29110-5-1-1" }

          let(:parsed) { Pubid::Iso.parse(subject) }
          let(:urn) { "urn:iso:std:iso-iec:29110:-5-1-1:CD" }

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
            expect(parsed.subpart.value).to eq("1-1")
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

          it "generates urn to pubid" do
            expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(subject)
          end
        end
      end

      context "enqiury" do
        # ISO/UNDP DIS 53001
        describe "ISO/UNDP DIS 53001" do
          subject { "ISO/UNDP DIS 53001" }

          let(:parsed) { Pubid::Iso.parse(subject) }
          let(:urn) { "urn:iso:std:iso-undp:53001:DIS" }

          it "parses publisher" do
            expect(parsed.publisher.publisher).to eq("ISO")
          end

          it "parses copublisher" do
            expect(parsed.publisher.copublisher.first).to eq("UNDP")
          end

          it "parses number" do
            expect(parsed.number.value).to eq("53001")
          end

          it "parses stage" do
            expect(parsed.typed_stage.stage_code).to eq("dis")
          end

          it "round-trips" do
            expect(parsed.to_s).to eq(subject)
          end

          it "generates urn" do
            expect(parsed.to_urn).to eq(urn)
          end

          it "generates urn to pubid" do
            expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(subject)
          end
        end
      end

      context "approval" do
        # ISO/FDIS 22868
        describe "ISO/FDIS 22868" do
          subject { "ISO/FDIS 22868" }

          let(:parsed) { Pubid::Iso.parse(subject) }
          let(:urn) { "urn:iso:std:iso:22868:FDIS" }

          it "parses publisher" do
            expect(parsed.publisher.publisher).to eq("ISO")
          end

          it "parses number" do
            expect(parsed.number.value).to eq("22868")
          end

          it "parses stage" do
            expect(parsed.typed_stage.stage_code).to eq("fdis")
          end

          it "round-trips" do
            expect(parsed.to_s).to eq(subject)
          end

          it "generates urn" do
            expect(parsed.to_urn).to eq(urn)
          end

          it "generates urn to pubid" do
            expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(subject)
          end
        end
      end

      context "publication" do
        # ISO/PRF 6709:2022
        describe "ISO/PRF 6709:2022" do
          subject { "ISO/PRF 6709:2022" }

          let(:parsed) { Pubid::Iso.parse(subject) }
          let(:undated) { "ISO/PRF 6709" }
          let(:urn) { "urn:iso:std:iso:6709:stage-60.00" }

          it "parses publisher" do
            expect(parsed.publisher.publisher).to eq("ISO")
          end

          it "parses number" do
            expect(parsed.number.value).to eq("6709")
          end

          it "parses date" do
            expect(parsed.date.year).to eq("2022")
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

          it "generates urn to undated pubid" do
            expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(undated)
          end
        end
      end
    end

    # Test stage with iteration
    context "stage with iteration" do
      describe "ISO/FDIS 21420.2" do
        subject { "ISO/FDIS 21420.2" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:21420:FDIS.2" }

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("fdis")
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

        it "generates urn to pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(subject)
        end
      end

      describe "ISO/CD2 14065:2018" do
        subject { "ISO/CD2 14065:2018" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:pubid) { "ISO/CD 14065.2:2018" }
        let(:undated) { Pubid::Iso.parse("ISO/CD 14065.2") }
        let(:urn) { "urn:iso:std:iso:14065:CD.2" }

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("cd")
        end

        it "parses iteration" do
          expect(parsed.stage_iteration.number).to eq("2")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(pubid)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end

        it "generates urn to undated pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(undated.to_s)
        end
      end
    end

    # Test legacy stages
    context "legacy stages" do
      # FCD maps to same stage as FPDAM (40.00 Enquiry/DAM)
      describe "ISO/IEC FCD 42010" do
        subject { "ISO/IEC FCD 42010" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn_pubid) { "ISO/IEC DIS 42010" }
        let(:urn) { "urn:iso:std:iso-iec:42010:stage-40.00" }

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("fcd")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end

        # We do not map 40.00 URN back to FCD
        it "generates urn to pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(Pubid::Iso.parse(urn_pubid).to_s)
        end
      end

      # PreCD
      describe "ISO/IEC preCD 29135" do
        subject { "ISO/IEC preCD 29135" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:pubid) { "ISO/IEC preCD 29135" }
        let(:urn) { "urn:iso:std:iso-iec:29135:stage-29.00" }

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("pcd")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(pubid)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end

        it "generates urn to pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(pubid)
        end
      end

      describe "ISO/PreCD3 17301-1" do
        subject { "ISO/PreCD3 17301-1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:pubid) { "ISO/preCD 17301-1.3" }
        let(:urn) { "urn:iso:std:iso:17301:-1:stage-29.00.v3" }

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("pcd")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(pubid)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end

        it "generates urn to pubid" do
          expect(Pubid::Iso.parse_urn(parsed.to_urn).to_s).to eq(pubid)
        end
      end
    end
  end

  context "urn parsing" do
    context "stage-draft as 40.00" do
      # Note: stage-draft is a legacy format not well-supported in URN parser
      # The DIS stage (40.00) is not applied from stage-draft
      describe "ISO/IEC FDIS 7816-6" do
        subject { "urn:iso:std:iso-iec:7816:-6:stage-draft" }

        let(:parsed) { Pubid::Iso.parse_urn(subject) }
        let(:pubid) { "ISO/IEC 7816-6" }

        it "parse pubid" do
          expect(parsed.to_s).to eq(pubid)
        end
      end
    end

    context "stage-stagecode" do
      describe "00.00" do
        describe "ISO/PWI 19171" do
          subject { "urn:iso:std:iso:19171:stage-00.00" }

          let(:parsed) { Pubid::Iso.parse_urn(subject) }
          let(:pubid) { "ISO/PWI 19171" }

          it "parse pubid" do
            expect(parsed.to_s).to eq(pubid)
          end
        end
      end

      describe "10.00" do
        describe "ISO/NP 10791-10" do
          subject { "urn:iso:std:iso:10791:stage-10.00" }

          let(:parsed) { Pubid::Iso.parse_urn(subject) }
          let(:pubid) { "ISO/NP 10791" }

          it "parse pubid" do
            expect(Pubid::Iso.parse_urn(subject).to_s).to eq(pubid)
          end
        end
      end

      describe "10.99" do
        # ISO/ASTM AWI 52932
        describe "ISO/ASTM AWI 52932" do
          subject { "urn:iso:std:iso-astm:52932:stage-10.99" }

          let(:parsed) { Pubid::Iso.parse_urn(subject) }
          let(:pubid) { "ISO/ASTM AWI 52932" }

          it "parse pubid" do
            expect(Pubid::Iso.parse_urn(subject).to_s).to eq(pubid)
          end
        end
      end

      describe "20.20" do
        # ISO/IEC WD 23773-1
        describe "ISO/IEC WD 23773-1" do
          subject { "urn:iso:std:iso-iec:23773:-1:stage-20.20" }

          let(:parsed) { Pubid::Iso.parse_urn(subject) }
          let(:pubid) { "ISO/IEC WD 23773-1" }

          it "parse pubid" do
            expect(Pubid::Iso.parse_urn(subject).to_s).to eq(pubid)
          end
        end
      end

      describe "30.00" do
        # ISO/IEC CD 29110-5-1-1
        describe "ISO/IEC CD 29110-5-1-1" do
          subject { "urn:iso:std:iso-iec:29110:-5-1-1:stage-30.00" }

          let(:parsed) { Pubid::Iso.parse_urn(subject) }
          let(:pubid) { "ISO/IEC CD 29110-5-1-1" }

          it "parse pubid" do
            expect(Pubid::Iso.parse_urn(subject).to_s).to eq(pubid)
          end
        end
      end

      describe "40.00" do
        # ISO/UNDP DIS 53001
        describe "ISO/UNDP DIS 53001" do
          subject { "urn:iso:std:iso-undp:53001:stage-40.00" }

          let(:parsed) { Pubid::Iso.parse_urn(subject) }
          let(:pubid) { "ISO/UNDP DIS 53001" }

          it "parse pubid" do
            expect(Pubid::Iso.parse_urn(subject).to_s).to eq(pubid)
          end
        end
      end

      describe "50.00" do
        # ISO/FDIS 22868
        describe "ISO/FDIS 22868" do
          subject { "urn:iso:std:iso:22868:stage-50.00" }

          let(:parsed) { Pubid::Iso.parse_urn(subject) }
          let(:pubid) { "ISO/FDIS 22868" }

          it "parse pubid" do
            expect(Pubid::Iso.parse_urn(subject).to_s).to eq(pubid)
          end
        end
      end

      describe "60.00" do
        # ISO/PRF 6709:2022
        describe "ISO/PRF 6709:2022" do
          subject { "urn:iso:std:iso:6709:stage-60.00" }

          let(:parsed) { Pubid::Iso.parse_urn(subject) }
          let(:undated) { "ISO/PRF 6709" }

          it "parse pubid to undated" do
            expect(Pubid::Iso.parse_urn(subject).to_s).to eq(undated)
          end
        end
      end

      describe "60.60" do
        # ISO/IEC 18014-4:2005
        describe "ISO/IEC 18014-4:2005" do
          subject { "urn:iso:std:iso-iec:18014:-4:stage-60.60" }

          let(:parsed) { Pubid::Iso.parse_urn(subject) }
          let(:pubid) { "ISO/IEC 18014-4" }

          it "parse pubid" do
            expect(Pubid::Iso.parse_urn(subject).to_s).to eq(pubid)
          end
        end
      end
    end

    context "stage-stagecode-iteration" do
      describe "50.00.v2" do
        # ISO/FDIS 21420.2
        subject { "urn:iso:std:iso:21420:stage-50.00.v2" }

        let(:pubid) { "ISO/FDIS 21420.2" }

        it "parse pubid" do
          expect(Pubid::Iso.parse_urn(subject).to_s).to eq(pubid)
        end
      end
    end
  end

  #     context "ISO/CD 105-C12" do
  #       let(:pubid) { "ISO/CD 105-C12" }
  #       let(:urn) { "urn:iso:std:iso:105:-C12:stage-draft" }

  #       it_behaves_like "converts pubid to pubid"
  #       it_behaves_like "converts pubid to urn"
  #       it_behaves_like "converts urn to pubid", "ISO/DIS 105-C12"
  #     end
end

#     context "ISO 14451-1:2013(en,fr,other)" do
#       let(:pubid) { "ISO 14451-1:2013(en,fr,other)" }
#       let(:urn) { "urn:iso:std:iso:14451:-1:en,fr,other" }

#       it_behaves_like "converts pubid to urn"
#       it_behaves_like "converts pubid to pubid"
#       it_behaves_like "converts urn to pubid", "ISO 14451-1(en,fr,other)"
#     end

#     context "ISO 17225-1:2014(R)" do
#       let(:original) { "ISO 17225-1:2014(R)" }
#       let(:pubid) { "ISO 17225-1:2014(ru)" }
#       let(:urn) { "urn:iso:std:iso:17225:-1:ru" }

#       it_behaves_like "converts pubid to urn"
#       it_behaves_like "converts pubid to pubid"
#       it_behaves_like "converts urn to pubid", "ISO 17225-1(ru)"
#     end

#     context "ISO 19115:2003(en,fr)" do
#       let(:pubid) { "ISO 19115:2003(en,fr)" }
#       let(:urn) { "urn:iso:std:iso:19115:en,fr" }

#       it_behaves_like "converts pubid to pubid"
#       it_behaves_like "converts pubid to urn"
#       it_behaves_like "converts urn to pubid", "ISO 19115(en,fr)"

#       it "has assigned IS type" do
#         expect(subject.type[:key]).to eq(:is)
#       end
#     end
