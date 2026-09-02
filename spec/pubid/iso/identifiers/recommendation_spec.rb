require "spec_helper"

RSpec.describe Pubid::Iso::Identifiers::Recommendation do
  subject { described_class }


  # Test normal dated recommendation
  context "parse normal dated recommendation" do
    # ISO/R 125:1966
    describe "ISO/R 125:1966" do
      subject { "ISO/R 125:1966" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:r:125" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("125")
      end

      it "parses part" do
        expect(parsed.part&.value).to be_nil
      end

      it "parses date" do
        expect(parsed.date.year).to eq("1966")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("rec")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("R")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # Legacy ISO Recommendations can carry an *alphabetic* part code whose
    # first letter is a Roman numeral (C, D, I, L, M, V, X) followed by a
    # non-Roman letter, e.g. "CS". Such a part must stay an alphabetic code
    # ("CS"), NOT be misread as a Roman-numeral part — the guard that
    # pubid 1.x added in #56 (fixing ~50 ISO Open Data deliverables).
    # Pinned here so the behaviour survives the pubid 2.x rewrite.
    describe "ISO/R 194-CS:1964 (alphabetic part, Roman first letter)" do
      subject { "ISO/R 194-CS:1964" }

      let(:parsed) { Pubid::Iso.parse(subject) }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("194")
      end

      it "keeps the alphabetic part code (not folded to a Roman numeral)" do
        expect(parsed.part.value).to eq("CS")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("1964")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("rec")
      end
    end
  end

  # Test normal undated recommendation
  context "parse normal undated recommendation" do
    # ISO/R 4
    describe "ISO/R 4" do
      subject { "ISO/R 4" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:r:4" }

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
        expect(parsed.typed_stage.type_code).to eq("rec")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("R")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Legacy version of ISO/R
  # ISO/R 170-1960 (parsed as date, not part)
  context "parse legacy format with date" do
    describe "ISO/R 170-1960" do
      subject { "ISO/R 170-1960" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:r:170" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("170")
      end

      it "parses part" do
        expect(parsed.part&.value).to be_nil
      end

      it "parses date" do
        expect(parsed.date&.year).to eq("1960")
      end

      it "normalizes to colon format" do
        expect(parsed.to_s).to eq("ISO/R 170:1960")
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("rec")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test recommendation with part
  context "parse recommendation with part" do
    # ISO/R 93-3:1969
    describe "ISO/R 93-3:1969" do
      subject { "ISO/R 93-3:1969" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:r:93:-3" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("93")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("3")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("1969")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("rec")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "provides typed_stage with abbreviation" do
        expect(parsed.typed_stage.abbr.first).to eq("R")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Test legacy part formats
  context "parse legacy part formats" do
    # Legacy version of ISO/R with part and date
    # Test legacy format ISO/R 93/1-1963 normalizes to ISO/R 93-1:1963
    describe "ISO/R 93/1-1963" do
      subject { "ISO/R 93/1-1963" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/R 93-1:1963" }
      let(:urn) { "urn:iso:std:iso:r:93:-1" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("93")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("1")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("1963")
      end

      it "normalizes to standard format" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("rec")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # Legacy version of ISO/R with part and date
    # Test roman numeral parts ISO/R 300/III-1968 normalizes to ISO/R 300-3:1968
    describe "ISO/R 300/III-1968" do
      subject { "ISO/R 300/III-1968" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/R 300-3:1968" }
      let(:urn) { "urn:iso:std:iso:r:300:-3" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("300")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("3")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("1968")
      end

      it "normalizes roman numeral to arabic" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("rec")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # Legacy version of ISO/R with part
    # update_codes normalizes ISO/R 657/IV to ISO/R 657-4:1969 (with date from update_codes.yaml)
    describe "ISO/R 657/IV" do
      subject { "ISO/R 657/IV" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:normalized) { "ISO/R 657-4:1969" }
      let(:urn) { "urn:iso:std:iso:r:657:-4" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("657")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("4")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("1969")
      end

      it "normalizes roman numeral to arabic" do
        expect(parsed.to_s).to eq(normalized)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("rec")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end
  end

  # Modern version of ISO/R
  # Test recommendations with multiple parts
  context "parse recommendations with multiple parts" do
    # ISO/R 105-1:1959
    describe "ISO/R 105-1:1959" do
      subject { "ISO/R 105-1:1959" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:r:105:-1" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("105")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("1")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("1959")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("rec")
      end

      it "provides stage code" do
        expect(parsed.typed_stage.stage_code).to eq("published")
      end

      it "generates urn" do
        expect(parsed.to_urn).to eq(urn)
      end
    end

    # Modern version of ISO/R
    # ISO/R 355-8:1973
    describe "ISO/R 355-8:1973" do
      subject { "ISO/R 355-8:1973" }

      let(:parsed) { Pubid::Iso.parse(subject) }
      let(:urn) { "urn:iso:std:iso:r:355:-8" }

      it "parses publisher" do
        expect(parsed.publisher.publisher).to eq("ISO")
      end

      it "parses number" do
        expect(parsed.number.value).to eq("355")
      end

      it "parses part" do
        expect(parsed.part.value).to eq("8")
      end

      it "parses date" do
        expect(parsed.date.year).to eq("1973")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "provides type code" do
        expect(parsed.typed_stage.type_code).to eq("rec")
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
