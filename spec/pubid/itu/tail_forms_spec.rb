# frozen_string_literal: true

require "spec_helper"

# The small-count remainder of the unindexable relaton-data-itu records.
RSpec.describe "ITU tail forms" do
  def parse(str) = Pubid::Itu.parse(str)

  def round_trips?(str, expected = str)
    parsed = parse(str)
    parsed.to_s == expected &&
      Pubid::Itu::Identifier.from_hash(parsed.to_hash).to_hash == parsed.to_hash
  end

  describe "attachment" do
    context "ITU-T H.350 attachment (08/2003)" do
      subject { "ITU-T H.350 attachment (08/2003)" }

      let(:parsed) { parse(subject) }

      it "flags the attachment" do
        expect(parsed.attachment).to be true
        expect(parsed.code.number).to eq("350")
      end

      it "round-trips" do
        expect(round_trips?(subject)).to be true
      end

      it "is a distinct document from the Recommendation" do
        expect(parsed).not_to eq(parse("ITU-T H.350 (08/2003)"))
      end
    end

    (1..6).each do |n|
      it "parses and round-trips ITU-T H.350.#{n} attachment" do
        expect(round_trips?("ITU-T H.350.#{n} attachment (08/2003)")).to be true
      end
    end

    it "does not serialize the flag for an ordinary recommendation" do
      expect(parse("ITU-T H.350 (08/2003)").to_hash).not_to have_key("attachment")
    end
  end

  describe "Recommendation ranges" do
    context "ITU-T Q.120-Q.139 (11/1988)" do
      subject { "ITU-T Q.120-Q.139 (11/1988)" }

      let(:parsed) { parse(subject) }

      it "keeps the lower bound as the document number" do
        expect(parsed.code.number).to eq("120")
        expect(parsed.root.number.to_s).to eq("120")
      end

      it "keeps the upper bound" do
        expect(parsed.range_end).to eq("Q.139")
      end

      it "round-trips" do
        expect(round_trips?(subject)).to be true
      end

      it "is distinct from the lower bound alone" do
        expect(parsed).not_to eq(parse("ITU-T Q.120 (11/1988)"))
      end
    end

    [
      "ITU-T Q.140-Q.180 (11/1988)",
      "ITU-T Q.251-Q.300 (11/1988)",
      "ITU-T Q.310-Q.332 (11/1988)",
      "ITU-T Q.400-Q.490 (11/1988)",
    ].each do |id|
      it "parses and round-trips #{id}" do
        expect(round_trips?(id)).to be true
      end
    end

    # `parts` requires digits after the dash, so the two cannot compete.
    it "does not mistake a part for a range" do
      parsed = parse("ITU-R BO.600-1")
      expect(parsed.code.parts).to eq(["1"])
      expect(parsed.range_end).to be_nil
    end
  end

  describe "appendix companion material" do
    {
      "ITU-T G.726 App. II test vectors (03/1991)" => "test vectors",
      "ITU-T G.727 App. I test vectors (03/1991)" => "test vectors",
      "ITU-T G.728 App. I Software (07/1995)" => "Software",
    }.each do |id, material|
      context id do
        let(:parsed) { parse(id) }

        it "captures the material" do
          expect(parsed).to be_a(Pubid::Itu::Identifiers::AppendixOfRecommendation)
          expect(parsed.material).to eq(material)
        end

        it "round-trips" do
          expect(round_trips?(id)).to be true
        end
      end
    end

    it "is distinct from the appendix itself, including by URN" do
      vectors = parse("ITU-T G.726 App. II test vectors (03/1991)")
      plain   = parse("ITU-T G.726 App. II (03/1991)")

      expect(vectors).not_to eq(plain)
      expect(vectors.to_urn).not_to eq(plain.to_urn)
    end
  end

  describe "a supplement of a series-only supplement" do
    {
      "ITU-T G Suppl. 39 (2006) Err. 1 (08/2006)" =>
        Pubid::Itu::Identifiers::Errata,
      "ITU-T X Suppl. 1 (1988) Cor. 1 (02/1990)" =>
        Pubid::Itu::Identifiers::Corrigendum,
      "ITU-T K Suppl. 1 (2020) Err. 1 (06/2021)" =>
        Pubid::Itu::Identifiers::Errata,
    }.each do |id, klass|
      context id do
        let(:parsed) { parse(id) }

        it "nests the series-only supplement as the base" do
          expect(parsed).to be_a(klass)
          expect(parsed.base).to be_a(Pubid::Itu::Identifiers::Supplement)
          expect(parsed.base.base).to be_nil
        end

        it "round-trips" do
          expect(round_trips?(id)).to be true
        end
      end
    end

    it "keeps different series' supplements distinct" do
      expect(parse("ITU-T G Suppl. 39 (2006) Err. 1"))
        .not_to eq(parse("ITU-T X Suppl. 39 (2006) Err. 1"))
    end
  end

  describe "whitespace normalisation" do
    # ITU's listings carry the occasional doubled space; whitespace is never
    # significant in an ITU identifier.
    it "collapses a doubled space" do
      expect(round_trips?("ITU-T D.271  (10/2016)", "ITU-T D.271 (10/2016)"))
        .to be true
    end

    it "treats the doubled and single spellings as one document" do
      expect(parse("ITU-T D.271  (10/2016)")).to eq(parse("ITU-T D.271 (10/2016)"))
    end

    it "strips surrounding whitespace" do
      expect(parse("  ITU-T G.711  ").to_s).to eq("ITU-T G.711")
    end
  end
end
