# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Itu::Identifiers::Addendum do
  describe "addendum on a recommendation" do
    # 22 relaton-data-itu records use the "Add. N" supplement type, which had
    # no token in the grammar and no identifier class.
    context "ITU-T I.363 (1993) Add. 1 (11/1993)" do
      subject { "ITU-T I.363 (1993) Add. 1 (11/1993)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses as Addendum" do
        expect(parsed).to be_a(described_class)
      end

      it "parses the base recommendation" do
        expect(parsed.base).to be_a(Pubid::Itu::Identifiers::Recommendation)
        expect(parsed.base.code.number).to eq("363")
        expect(parsed.base.date.year).to eq("1993")
      end

      it "parses the addendum ordinal and date" do
        expect(parsed.number).to eq("1")
        expect(parsed.date.year).to eq("1993")
        expect(parsed.date.month).to eq("11")
      end

      it "round-trips to_s" do
        expect(parsed.to_s).to eq(subject)
      end

      it "serializes with its own _type" do
        expect(parsed.to_hash["_type"]).to eq("pubid:itu:addendum")
      end

      it "round-trips through from_hash" do
        expect(Pubid::Itu::Identifier.from_hash(parsed.to_hash).to_hash)
          .to eq(parsed.to_hash)
      end

      it "keeps root.number on the base document, for relaton-index" do
        expect(parsed.root.number.to_s).to eq("363")
      end
    end

    [
      "ITU-T M.3010 (1996) Add. 1 (06/1998)",
      "ITU-T O.191 (1997) Add. 1 (10/1997)",
      "ITU-T Q.1218 (1995) Add. 1 (09/1997)",
      "ITU-T X.680 Add. 1",
    ].each do |id|
      it "parses and round-trips #{id}" do
        parsed = Pubid::Itu.parse(id)
        expect(parsed).to be_a(described_class)
        expect(parsed.to_s).to eq(id)
      end
    end

    it "is distinct from an Amendment with the same ordinal" do
      add = Pubid::Itu.parse("ITU-T X.680 Add. 1")
      amd = Pubid::Itu.parse("ITU-T X.680 Amd. 1")

      expect(add).not_to eq(amd)
      expect(amd).not_to eq(add)
    end
  end

  describe "an unknown supplement type" do
    # The builder's case statement used to fall through to a nil class and
    # die with `NoMethodError: undefined method 'new' for nil`. Any future
    # token added to the grammar without a matching class should say so.
    it "raises a diagnosable error rather than NoMethodError" do
      builder = Pubid::Itu::Builder.new
      data = { supplement_type: "Xyz", supplement_number: "1", sector: "T" }

      expect { builder.build_supplement(data) }
        .to raise_error(ArgumentError, /Unknown ITU supplement type/)
    end
  end
end
