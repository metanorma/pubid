require "spec_helper"

RSpec.describe Pubid::Iso::Identifiers::DirectivesSupplement do
  subject { described_class }


  # Test basic directives supplement identifiers
  context "basic directives supplement identifiers" do
    describe "ISO/IEC DIR 1 ISO SUP:2022" do
      subject { "ISO/IEC DIR 1 ISO SUP:2022" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:doc:iso-iec:dir:1:sup:iso:2022" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("1")
      end

      it "parses base identifier type" do
        expect(parsed.base.typed_stage.type_code).to eq("dir")
      end

      it "parses supplement date" do
        expect(parsed.date.year).to eq("2022")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("dir-sup")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("DIR SUP")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC DIR IEC SUP:2022" do
      subject { "ISO/IEC DIR IEC SUP:2022" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:doc:iso-iec:dir:sup:iec:2022" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier type" do
        expect(parsed.base.typed_stage.type_code).to eq("dir")
      end

      it "parses supplement date" do
        expect(parsed.date.year).to eq("2022")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("dir-sup")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("DIR SUP")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC DIR 1 IEC SUP" do
      subject { "ISO/IEC DIR 1 IEC SUP" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:doc:iso-iec:dir:1:sup:iec" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("1")
      end

      it "parses base identifier type" do
        expect(parsed.base.typed_stage.type_code).to eq("dir")
      end

      it "parses supplement date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("dir-sup")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("DIR SUP")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC DIR IEC SUP" do
      subject { "ISO/IEC DIR IEC SUP" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:doc:iso-iec:dir:sup:iec" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier type" do
        expect(parsed.base.typed_stage.type_code).to eq("dir")
      end

      it "parses supplement date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("dir-sup")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("DIR SUP")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC DIR 1 ISO SUP" do
      subject { "ISO/IEC DIR 1 ISO SUP" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:doc:iso-iec:dir:1:sup:iso" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("1")
      end

      it "parses base identifier type" do
        expect(parsed.base.typed_stage.type_code).to eq("dir")
      end

      it "parses supplement date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("dir-sup")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("DIR SUP")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test JTC variations
  context "JTC variations" do
    describe "ISO/IEC DIR JTC 1 SUP:2021" do
      subject { "ISO/IEC DIR JTC 1 SUP:2021" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:doc:iso-iec:dir:jtc:1:sup:2021" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier type" do
        expect(parsed.base.typed_stage.type_code).to eq("dir")
      end

      it "parses supplement date" do
        expect(parsed.date.year).to eq("2021")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("dir-sup")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("DIR SUP")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC DIR JTC 1 SUP" do
      subject { "ISO/IEC DIR JTC 1 SUP" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:doc:iso-iec:dir:jtc:1:sup" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier type" do
        expect(parsed.base.typed_stage.type_code).to eq("dir")
      end

      it "parses supplement date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("dir-sup")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("DIR SUP")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test format normalization
  context "format normalization" do
    describe "ISO/IEC Directives, IEC Supplement:2022" do
      subject { "ISO/IEC Directives, IEC Supplement:2022" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/IEC DIR IEC SUP:2022" }
      let(:urn) { "urn:iso:doc:iso-iec:dir:sup:iec:2022" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier type" do
        expect(parsed.base.typed_stage.type_code).to eq("dir")
      end

      it "parses supplement date" do
        expect(parsed.date.year).to eq("2022")
      end

      it "normalizes format" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("dir-sup")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("DIR SUP")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    describe "ISO/IEC Directives, Part 1 -- Consolidated ISO Supplement" do
      subject { "ISO/IEC Directives, Part 1 -- Consolidated ISO Supplement" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/IEC DIR 1 ISO SUP" }
      let(:urn) { "urn:iso:doc:iso-iec:dir:1:sup:iso" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("1")
      end

      it "parses base identifier type" do
        expect(parsed.base.typed_stage.type_code).to eq("dir")
      end

      it "parses supplement date" do
        expect(parsed.date).to be_nil
      end

      it "normalizes format" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("dir-sup")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("DIR SUP")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test editions
  context "editions" do
    describe "ISO/IEC DIR 1 ISO SUP Edition 13" do
      subject { "ISO/IEC DIR 1 ISO SUP Edition 13" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:doc:iso-iec:dir:1:sup:iso:ed-13" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses copublisher" do
        expect(parsed.publisher.copublisher.first).to eq("IEC")
      end

      it "parses base identifier number" do
        expect(parsed.base.number.value).to eq("1")
      end

      it "parses base identifier type" do
        expect(parsed.base.typed_stage.type_code).to eq("dir")
      end

      it "parses edition" do
        expect(parsed.edition&.value).to eq("13")
      end

      it "parses supplement date" do
        expect(parsed.date).to be_nil
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("dir-sup")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("DIR SUP")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end
end
