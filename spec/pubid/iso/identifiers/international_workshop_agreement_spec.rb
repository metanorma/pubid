require "spec_helper"

RSpec.describe Pubid::Iso::Identifiers::InternationalWorkshopAgreement do
  subject { described_class }


  # Test normal dated IWA
  context "parse normal dated international workshop agreement" do
    # IWA 1:2001
    describe "IWA 1:2001" do
      subject { "IWA 1:2001" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:iwa:1" }

      it "parses publisher" do
        expect(parsed.publisher).to be_nil
      end

      it "parses number" do
        expect(parsed.number.value).to eq("1")
      end

      it "parses part" do
        expect(parsed.part&.value).to be_nil
      end

      it "parses date" do
        expect(parsed.date.year).to eq("2001")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("iwa")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # IWA 32:2019(en)
    describe "IWA 32:2019(en)" do
      subject { "IWA 32:2019(en)" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:iwa:32:en" }

      it "parses publisher" do
        expect(parsed.publisher).to be_nil
      end

      it "parses number" do
        expect(parsed.number.value).to eq("32")
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
    end
  end

  # Test normal undated IWA
  context "parse normal undated international workshop agreement" do
    # IWA 8
    describe "IWA 8" do
      subject { "IWA 8" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:iwa:8" }

      it "parses publisher" do
        expect(parsed.publisher).to be_nil
      end

      it "parses number" do
        expect(parsed.number.value).to eq("8")
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

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test IWA with parts
  context "parse international workshop agreement with parts" do
    # IWA 14-1:2013
    describe "IWA 14-1:2013" do
      subject { "IWA 14-1:2013" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:iwa:14:-1" }

      it "parses publisher" do
        expect(parsed.publisher).to be_nil
      end

      it "parses number" do
        expect(parsed.number.value).to eq("14")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("1")
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

  # Test stages
  context "stages" do
    context "proposal" do
      # NP IWA 21
      describe "NP IWA 21" do
        subject { "NP IWA 21" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:iwa:21:stage-10.00" }

        it "parses publisher" do
          expect(parsed.publisher).to be_nil
        end

        it "parses number" do
          expect(parsed.number.value).to eq("21")
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
      # AWI IWA 39
      describe "AWI IWA 39" do
        subject { "AWI IWA 39" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:iwa:39:stage-10.99" }

        it "parses publisher" do
          expect(parsed.publisher).to be_nil
        end

        it "parses number" do
          expect(parsed.number.value).to eq("39")
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

      # WD IWA 19
      describe "WD IWA 19" do
        subject { "WD IWA 19" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:iwa:19:WD" }

        it "parses publisher" do
          expect(parsed.publisher).to be_nil
        end

        it "parses number" do
          expect(parsed.number.value).to eq("19")
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

      # WD IWA 48(en)
      describe "WD IWA 48(en)" do
        subject { "WD IWA 48(en)" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:iwa:48:WD:en" }

        it "parses publisher" do
          expect(parsed.publisher).to be_nil
        end

        it "parses number" do
          expect(parsed.number.value).to eq("48")
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
      # CD IWA 37
      describe "CD IWA 37" do
        subject { "CD IWA 37" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:iwa:37:CD" }

        it "parses publisher" do
          expect(parsed.publisher).to be_nil
        end

        it "parses number" do
          expect(parsed.number.value).to eq("37")
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

      # CD IWA 37-1
      describe "CD IWA 37-1" do
        subject { "CD IWA 37-1" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:iwa:37:-1:CD" }

        it "parses publisher" do
          expect(parsed.publisher).to be_nil
        end

        it "parses number" do
          expect(parsed.number.value).to eq("37")
        end

        it "parses part" do
          expect(parsed.part.value).to eq("1")
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

    context "publication" do
      # PRF IWA 36
      describe "PRF IWA 36" do
        subject { "PRF IWA 36" }

        let(:parsed) { Pubid::Iso.parse(subject) }
        let(:urn) { "urn:iso:std:iso:iwa:36:stage-50.00" }

        it "parses publisher" do
          expect(parsed.publisher).to be_nil
        end

        it "parses number" do
          expect(parsed.number.value).to eq("36")
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
    # WD IWA 48.2
    describe "WD IWA 48.2" do
      subject { "WD IWA 48.2" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:iwa:48:WD.2" }

      it "parses publisher" do
        expect(parsed.publisher).to be_nil
      end

      it "parses number" do
        expect(parsed.number.value).to eq("48")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("wd")
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

  # Test aberrations
  context "aberrations" do
    # ISO/WD IWA 19 -> WD IWA 19
    describe "ISO/WD IWA 19" do
      subject { "ISO/WD IWA 19" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "WD IWA 19" }
      let(:urn) { "urn:iso:std:iso:iwa:19:WD" }

      # Publisher is not rendered but still exists
      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("19")
      end

      it "parses stage" do
        expect(parsed.typed_stage.stage_code).to eq("wd")
      end

      it "normalizes format" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end
end
