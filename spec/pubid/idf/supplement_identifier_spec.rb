require "spec_helper"

RSpec.describe Pubid::Idf::SupplementIdentifier do
  subject { described_class }

  describe "inheritance" do
    it "inherits from Identifier" do
      expect(described_class.superclass).to eq(Pubid::Idf::Identifier)
    end
  end

  describe "shared attributes" do
    let(:parsed) { Pubid::Idf.parse("IDF 125:1988/AMD 1:2023") }

    it "has base attribute" do
      expect(parsed.respond_to?(:base)).to be true
    end

    it "base returns the base identifier" do
      expect(parsed.base).to be_a(Pubid::Idf::Identifiers::InternationalStandard)
    end

    it "base has the correct number" do
      expect(parsed.base.number).to eq("125")
    end
  end

  describe "shared to_s behavior" do
    context "Amendment" do
      subject { Pubid::Idf.parse("IDF 125:1988/AMD 1:2023") }

      it "renders supplement with base" do
        expect(subject.to_s).to eq("IDF 125:1988/AMD 1:2023")
      end

      it "parses and round-trips amendment" do
        expect(subject.class).to eq(Pubid::Idf::Identifiers::Amendment)
        expect(subject.to_s).to eq("IDF 125:1988/AMD 1:2023")
      end
    end

    context "Corrigendum" do
      subject { Pubid::Idf.parse("IDF 125:1988/COR 1:2023") }

      it "renders supplement with base" do
        expect(subject.to_s).to eq("IDF 125:1988/COR 1:2023")
      end

      it "parses and round-trips corrigendum" do
        expect(subject.class).to eq(Pubid::Idf::Identifiers::Corrigendum)
        expect(subject.to_s).to eq("IDF 125:1988/COR 1:2023")
      end
    end

    context "supplement without date" do
      subject { Pubid::Idf.parse("IDF 125:1988/AMD 1") }

      it "renders supplement without date" do
        expect(subject.to_s).to eq("IDF 125:1988/AMD 1")
      end

      it "has no date on the supplement" do
        expect(subject.date).to be_nil
      end

      it "has the base identifier's date" do
        expect(subject.base.date.year).to eq("1988")
      end
    end

    context "supplement with part number" do
      subject { Pubid::Idf.parse("IDF 140-1:2007/AMD 1:2012") }

      it "renders supplement with part" do
        expect(subject.to_s).to eq("IDF 140-1:2007/AMD 1:2012")
      end

      it "parses base part number" do
        expect(subject.base.part).to eq("1")
      end
    end
  end
end
