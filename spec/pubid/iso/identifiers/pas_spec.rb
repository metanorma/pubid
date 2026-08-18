require "spec_helper"

RSpec.describe Pubid::Iso::Identifiers::Pas do
  subject { described_class }


  # Test normal dated PAS
  context "parse normal dated pas" do
    # ISO/PAS 5643:2021
    describe "ISO/PAS 5643:2021" do
      subject { "ISO/PAS 5643:2021" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:pas:5643" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("5643")
      end

      it "parses part" do
        expect(parsed.part&.value).to be_nil
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2021")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("pas")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("PAS")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test normal undated PAS
  context "parse normal undated pas" do
    # ISO/PAS 23678-3
    describe "ISO/PAS 23678-3" do
      subject { "ISO/PAS 23678-3" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:pas:23678:-3" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("23678")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("3")
      end

      it "parses date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("pas")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("PAS")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test PAS with parts
  context "parse pas with parts" do
    # ISO/PAS 17208-1:2012
    describe "ISO/PAS 17208-1:2012" do
      subject { "ISO/PAS 17208-1:2012" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:pas:17208:-1" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("17208")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("1")
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
    context "copublisher as SAE" do
      # ISO/SAE PAS 22736:2021
      describe "ISO/SAE PAS 22736:2021" do
        subject { "ISO/SAE PAS 22736:2021" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-sae:pas:22736" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("SAE")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("22736")
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
      end
    end
  end

  # Test stages
  context "stages" do
    context "preparatory" do
      # ISO/AWI PAS 24499
      describe "ISO/AWI PAS 24499" do
        subject { "ISO/AWI PAS 24499" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:pas:24499:stage-10.99" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("24499")
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
      end

      # ISO/WD PAS 34507
      describe "ISO/WD PAS 34507" do
        subject { "ISO/WD PAS 34507" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:pas:34507:WD" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("34507")
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
      # ISO/CD PAS 22399
      describe "ISO/CD PAS 22399" do
        subject { "ISO/CD PAS 22399" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:pas:22399:CD" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("22399")
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

    context "enquiry" do
      # ISO/DPAS 45007
      describe "ISO/DPAS 45007" do
        subject { "ISO/DPAS 45007" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:pas:45007:stage-40.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("45007")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("dpas")
        end

        it "round-trips" do
          expect(parsed.to_s).to eq(subject)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      # ISO/DPAS 5643:2021(E)
      describe "ISO/DPAS 5643:2021(E)" do
        subject { "ISO/DPAS 5643:2021(E)" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        # V2 preserves original format
        let(:normalized) do
          "ISO/DPAS 5643:2021(E)"
        end
        let(:urn) { "urn:iso:std:iso:pas:5643:stage-40.00:en" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("5643")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2021")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("dpas")
        end

        it "normalizes language" do
          expect(parsed.to_s).to eq(normalized)
        end

        it "generates urn" do
          expect(parsed.to_urn).to eq(urn)
        end
      end

      # ISO/DPAS 5474-6
      describe "ISO/DPAS 5474-6" do
        subject { "ISO/DPAS 5474-6" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:pas:5474:-6:stage-40.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("5474")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("6")
        end

        it "parses stage" do
          expect(parsed.typed_stage.stage_code).to eq("dpas")
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
      # ISO/PRF PAS 22596
      describe "ISO/PRF PAS 22596" do
        subject { "ISO/PRF PAS 22596" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:pas:22596:stage-60.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("22596")
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

      # ISO/PRF PAS 5643:2021
      describe "ISO/PRF PAS 5643:2021" do
        subject { "ISO/PRF PAS 5643:2021" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:pas:5643:stage-60.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("5643")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2021")
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

      # ISO/SAE PRF PAS 22736:2021
      describe "ISO/SAE PRF PAS 22736:2021" do
        subject { "ISO/SAE PRF PAS 22736:2021" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso-sae:pas:22736:stage-60.00" }

        it "parses publisher" do
          expect(parsed.publisher.publisher).to eq("ISO")
        end

        it "parses copublisher" do
          expect(parsed.publisher.copublisher.first).to eq("SAE")
        end

        it "parses number" do
          expect(parsed.number.value).to eq("22736")
        end

        it "parses date" do
          expect(parsed.date.year).to eq("2021")
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
end
