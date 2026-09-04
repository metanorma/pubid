require "spec_helper"

RSpec.describe Pubid::Iso::CombinedIdentifier do
  subject { described_class }

  context "joint identifiers" do
    # ISO 4214:2022 | IDF/RM 254:2022
    describe "ISO 4214:2022 | IDF/RM 254:2022" do
      subject { "ISO 4214:2022 | IDF/RM 254:2022" }

      let(:parsed) { described_class.parse(subject) }
      let(:base) { parsed.base }
      let(:additional_identifier) { parsed.additional_identifiers.first }

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "has joint identifier of ReviewedMethod class" do
        expect(additional_identifier).to be_a(Pubid::Idf::Identifiers::ReviewedMethod)
      end

      it "parses joint identifier number" do
        expect(additional_identifier.number).to eq("254")
      end

      it "parses joint identifier date" do
        expect(additional_identifier.date.year).to eq("2022")
      end

      it "parses joint identifier part" do
        expect(additional_identifier.part).to be_nil
      end

      # Test main ISO identifier attributes are not corrupted
      it "parses ISO publisher" do
        expect(base.publisher.body).to eq("ISO")
      end

      it "parses ISO number" do
        expect(base.number.value).to eq("4214")
      end

      it "parses ISO date" do
        expect(base.date.year).to eq("2022")
      end

      it "parses ISO part" do
        expect(base.part).to be_nil
      end

      it "provides ISO type code" do
        expect(base.type.type_code).to eq("is")
      end

      it "provides ISO stage code" do
        expect(base.stage.stage_code).to eq("published")
      end
    end

    # ISO/CD 24191.3 | IDF 263
    describe "ISO/CD 24191.3 | IDF 263" do
      subject { "ISO/CD 24191.3 | IDF 263" }

      let(:parsed) { described_class.parse(subject) }
      let(:base) { parsed.base }
      let(:additional_identifier) { parsed.additional_identifiers.first }

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "has joint identifier of InternationalStandard class" do
        expect(additional_identifier).to be_a(Pubid::Idf::Identifiers::InternationalStandard)
      end

      it "parses joint identifier number" do
        expect(additional_identifier.number).to eq("263")
      end

      it "parses joint identifier date" do
        expect(additional_identifier.date).to be_nil
      end

      it "parses joint identifier part" do
        expect(additional_identifier.part).to be_nil
      end

      # Test main ISO identifier attributes are not corrupted
      it "parses ISO publisher" do
        expect(base.publisher.body).to eq("ISO")
      end

      it "parses ISO number" do
        expect(base.number.value).to eq("24191")
      end

      it "parses ISO stage" do
        expect(base.stage.stage_code).to eq("cd")
      end

      it "parses ISO stage iteration" do
        expect(base.stage_iteration.number).to eq("3")
      end

      it "parses ISO date" do
        expect(base.date).to be_nil
      end

      it "parses ISO part" do
        expect(base.part).to be_nil
      end

      it "provides ISO type code" do
        expect(base.type.type_code).to eq("is")
      end
    end

    # ISO/WD 14501 | IDF 171:2017
    describe "ISO/WD 14501 | IDF 171:2017" do
      subject { "ISO/WD 14501 | IDF 171:2017" }

      let(:parsed) { described_class.parse(subject) }
      let(:base) { parsed.base }
      let(:additional_identifier) { parsed.additional_identifiers.first }

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "has joint identifier of InternationalStandard class" do
        expect(additional_identifier).to be_a(Pubid::Idf::Identifiers::InternationalStandard)
      end

      it "parses joint identifier number" do
        expect(additional_identifier.number).to eq("171")
      end

      it "parses joint identifier date" do
        expect(additional_identifier.date.year).to eq("2017")
      end

      it "parses joint identifier part" do
        expect(additional_identifier.part).to be_nil
      end

      # Test main ISO identifier attributes are not corrupted
      it "parses ISO publisher" do
        expect(base.publisher.body).to eq("ISO")
      end

      it "parses ISO number" do
        expect(base.number.value).to eq("14501")
      end

      it "parses ISO stage" do
        expect(base.stage.stage_code).to eq("wd")
      end

      it "parses ISO date" do
        expect(base.date).to be_nil
      end

      it "parses ISO part" do
        expect(base.part).to be_nil
      end

      it "provides ISO type code" do
        expect(base.type.type_code).to eq("is")
      end
    end

    # ISO 8262-2 | IDF 124-2:2005
    describe "ISO 8262-2 | IDF 124-2:2005" do
      subject { "ISO 8262-2 | IDF 124-2:2005" }

      let(:parsed) { described_class.parse(subject) }
      let(:base) { parsed.base }
      let(:additional_identifier) { parsed.additional_identifiers.first }

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end

      it "has joint identifier of InternationalStandard class" do
        expect(additional_identifier).to be_a(Pubid::Idf::Identifiers::InternationalStandard)
      end

      it "parses joint identifier number" do
        expect(additional_identifier.number).to eq("124")
      end

      it "parses joint identifier part" do
        expect(additional_identifier.part).to eq("2")
      end

      it "parses joint identifier date" do
        expect(additional_identifier.date.year).to eq("2005")
      end

      # Test main ISO identifier attributes are not corrupted
      it "parses ISO publisher" do
        expect(base.publisher.body).to eq("ISO")
      end

      it "parses ISO number" do
        expect(base.number.value).to eq("8262")
      end

      it "parses ISO part" do
        expect(base.part.value).to eq("2")
      end

      it "parses ISO date" do
        expect(base.date).to be_nil
      end

      it "provides ISO type code" do
        expect(base.type.type_code).to eq("is")
      end

      it "provides ISO stage code" do
        expect(base.stage.stage_code).to eq("published")
      end
    end
  end
end
