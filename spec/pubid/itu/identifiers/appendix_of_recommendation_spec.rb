# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Itu::Identifiers::AppendixOfRecommendation do
  describe "a labelled appendix of a Recommendation" do
    context "ITU-T G.101 App. I (05/2000)" do
      subject { "ITU-T G.101 App. I (05/2000)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      it "parses as an appendix" do
        expect(parsed).to be_a(described_class)
        expect(parsed.number).to eq("I")
      end

      it "keeps the appendixed document as the base" do
        expect(parsed.base).to be_a(Pubid::Itu::Identifiers::Recommendation)
        expect(parsed.base.series.series).to eq("G")
        expect(parsed.base.code.number).to eq("101")
      end

      it "carries its own date" do
        expect(parsed.date.year).to eq("2000")
        expect(parsed.date.month).to eq("05")
      end

      it "round-trips to_s and the hash" do
        expect(parsed.to_s).to eq(subject)
        expect(Pubid::Itu::Identifier.from_hash(parsed.to_hash).to_hash)
          .to eq(parsed.to_hash)
      end

      it "serializes with its own _type" do
        expect(parsed.to_hash["_type"])
          .to eq("pubid:itu:appendix-of-recommendation")
      end

      it "keys on the appendixed document's number for relaton-index" do
        expect(parsed.root.number.to_s).to eq("101")
      end

      it "gets an appendix URN segment" do
        expect(parsed.to_urn).to eq("urn:itu:t:G.101:appendix:i:05/2000")
      end
    end

    context "a base carrying its own date — ITU-T G.722 (1988) App. IV (11/2006)" do
      subject { "ITU-T G.722 (1988) App. IV (11/2006)" }

      let(:parsed) { Pubid::Itu.parse(subject) }

      # The two dates must not collide in the flattened parse tree — the same
      # reason annex_body wraps its base in `.as(:base)`.
      it "keeps the base date separate from the appendix date" do
        expect(parsed.base.date.year).to eq("1988")
        expect(parsed.base.date.month).to be_nil
        expect(parsed.date.year).to eq("2006")
        expect(parsed.date.month).to eq("11")
      end

      it "round-trips" do
        expect(parsed.to_s).to eq(subject)
      end
    end

    [
      "ITU-T G.113 App. I (05/2002)",
      "ITU-T G.131 App. II (09/1999)",
      "ITU-T G.711 App. II (02/2000)",
      "ITU-T G.722 (1988) App. III (11/2006)",
      "ITU-T H.323 App. III",
      "ITU-T P.59 App. I",
      "ITU-T Q.3 App. I",
    ].each do |id|
      it "parses and round-trips #{id}" do
        parsed = Pubid::Itu.parse(id)
        expect(parsed).to be_a(described_class)
        expect(parsed.to_s).to eq(id)
      end
    end

    describe "the no-space spelling ITU-T O.9 App.I (1998)" do
      subject { "ITU-T O.9 App.I (1998)" }

      # Rendering normalises to the canonical spaced spelling; the hash — the
      # relaton gate — still round-trips.
      it "parses and normalises the spacing" do
        parsed = Pubid::Itu.parse(subject)
        expect(parsed.number).to eq("I")
        expect(parsed.to_s).to eq("ITU-T O.9 App. I (1998)")
        expect(Pubid::Itu::Identifier.from_hash(parsed.to_hash).to_hash)
          .to eq(parsed.to_hash)
      end
    end

    describe "distinctness" do
      it "distinguishes appendix labels" do
        expect(Pubid::Itu.parse("ITU-T G.113 App. I"))
          .not_to eq(Pubid::Itu.parse("ITU-T G.113 App. II"))
      end

      it "is not equal to the appendixed Recommendation" do
        expect(Pubid::Itu.parse("ITU-T G.113 App. I"))
          .not_to eq(Pubid::Itu.parse("ITU-T G.113"))
      end

      it "is not equal to the annex with the same label" do
        expect(Pubid::Itu.parse("ITU-T G.113 App. I"))
          .not_to eq(Pubid::Itu.parse("ITU-T G.113 Annex I"))
      end

      it "gets a distinct MR string per appendix" do
        one = Pubid::Itu.parse("ITU-T G.113 App. I (05/2002)").to_mr_string
        two = Pubid::Itu.parse("ITU-T G.113 App. II (05/2002)").to_mr_string

        expect(one).not_to eq(two)
      end
    end
  end

  describe "supplements of an appendix" do
    {
      "ITU-T G.729 App. I (2002) Amd. 1 (05/2006)" =>
        Pubid::Itu::Identifiers::Amendment,
      "ITU-T O.9 App.I (1998) Err. 1 (03/1999)" =>
        Pubid::Itu::Identifiers::Errata,
    }.each do |id, klass|
      it "nests the appendix inside the supplement for #{id}" do
        parsed = Pubid::Itu.parse(id)
        expect(parsed).to be_a(klass)
        expect(parsed.base).to be_a(described_class)
      end
    end

    it "keys the supplement on the appendixed document's number" do
      parsed = Pubid::Itu.parse("ITU-T G.729 App. I (2002) Amd. 1 (05/2006)")
      expect(parsed.root.number.to_s).to eq("729")
    end

    # The URN generator used to hard-code AnnexOfRecommendation as the only
    # wrapper whose identity sits one level deeper; without widening it, a
    # supplement of an appendix emitted "urn:itu:itu".
    it "does not emit a degenerate URN" do
      urn = Pubid::Itu.parse("ITU-T G.729 App. I (2002) Amd. 1 (05/2006)").to_urn
      expect(urn).to start_with("urn:itu:t:G.729:appendix:i")
    end
  end

  describe "existing annex behaviour is untouched" do
    [
      "ITU-T A.23 Annex A (06/2014)",
      "ITU-T G.729 Annex C+ (02/2000)",
      "ITU-T G.729 Annex B (1996) Cor. 3 (03/2001)",
    ].each do |id|
      it "still round-trips #{id}" do
        expect(Pubid::Itu.parse(id).to_s).to eq(id)
      end
    end
  end
end
