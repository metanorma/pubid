# frozen_string_literal: true

require "spec_helper"

# Two print-form suffixes that may trail an ITU code with a separating space:
# the edition word ("ITU-T E.250 bis") and the qualifier letter
# ("ITU-T D.200 R", "ITU-T Q.2931 B"). Together they account for 240 of the
# unindexable relaton-data-itu records.
RSpec.describe "ITU code suffixes" do
  def parse(str) = Pubid::Itu.parse(str)

  def round_trips?(str)
    parsed = parse(str)
    parsed.to_s == str &&
      Pubid::Itu::Identifier.from_hash(parsed.to_hash).to_hash == parsed.to_hash
  end

  describe "space-separated edition word" do
    context "ITU-T E.250 bis (12/1972)" do
      subject { "ITU-T E.250 bis (12/1972)" }

      let(:parsed) { parse(subject) }

      it "captures the suffix without the space" do
        expect(parsed.code.number).to eq("250")
        expect(parsed.code.series_suffix).to eq("bis")
      end

      it "flags the spacing so it renders back" do
        expect(parsed.code.series_suffix_spaced).to be true
        expect(parsed.to_s).to eq(subject)
      end

      it "round-trips through from_hash, rendering included" do
        rebuilt = Pubid::Itu::Identifier.from_hash(parsed.to_hash)
        expect(rebuilt.to_hash).to eq(parsed.to_hash)
        expect(rebuilt.to_s).to eq(subject)
      end
    end

    [
      "ITU-T V.25 ter",
      "ITU-T F.11 bis (12/1972)",
      "ITU-T Q.107 bis (11/1988)",
      "ITU-T R.20 bis (10/1984)",
      "ITU-T T.30 bis (11/1988)",
      "ITU-T X.25 bis (10/1984)",
      "ITU-T E.211/Q.11 quater (10/1984)",
      "ITU-T Q.1600 bis (1999) Amd. 1 (10/2009)",
    ].each do |id|
      it "parses and round-trips #{id}" do
        expect(round_trips?(id)).to be true
      end
    end

    # A real misspelling in ITU's own data; preserved verbatim rather than
    # silently corrected to "quater", which would merge two distinct records.
    it "preserves the corpus misspelling 'quarter'" do
      expect(round_trips?("ITU-T E.211/Q.11 quarter (11/1980)")).to be true
    end

    it "distinguishes the edition from the plain recommendation" do
      expect(parse("ITU-T E.250 bis")).not_to eq(parse("ITU-T E.250"))
    end

    it "distinguishes bis from ter" do
      expect(parse("ITU-T V.25 bis")).not_to eq(parse("ITU-T V.25 ter"))
    end
  end

  describe "the glued edition word is unchanged — issue #231" do
    # This spelling is spec-locked in recommendation_spec.rb; the spaced form
    # must not disturb it, hence the separate spacing flag rather than storing
    # the space inside series_suffix.
    %w[ITU-T\ X.50bis ITU-T\ V.8bis ITU-T\ V.31bis].each do |id|
      it "still round-trips #{id}" do
        expect(round_trips?(id)).to be true
      end
    end

    it "keeps series_suffix free of whitespace" do
      expect(parse("ITU-T X.50bis").code.series_suffix).to eq("bis")
      expect(parse("ITU-T E.250 bis").code.series_suffix).to eq("bis")
    end

    it "does not flag the glued form" do
      expect(parse("ITU-T X.50bis").code.series_suffix_spaced).to be false
    end

    it "treats glued and spaced spellings of one number as one document" do
      expect(parse("ITU-T V.8bis")).to eq(parse("ITU-T V.8 bis"))
    end
  end

  describe "trailing qualifier letter" do
    context "ITU-T D.200 R (10/1976)" do
      subject { "ITU-T D.200 R (10/1976)" }

      let(:parsed) { parse(subject) }

      it "captures the qualifier" do
        expect(parsed.code.number).to eq("200")
        expect(parsed.code.qualifier).to eq("R")
      end

      it "round-trips" do
        expect(round_trips?(subject)).to be true
      end

      it "is distinct from the unqualified recommendation" do
        expect(parsed).not_to eq(parse("ITU-T D.200 (10/1976)"))
      end
    end

    [
      "ITU-T D.201 R (10/1984)",
      "ITU-T D.300 R (03/1995)",
      "ITU-T E.230 R (11/1988)",
      "ITU-T Q.2931 B",
      "ITU-T Q.2931 F",
      "ITU-T Q.1912.5 C",
      "ITU-T Q.2963.1 D",
      "ITU-T R.38 A",
      "ITU-T R.38 B",
    ].each do |id|
      it "parses and round-trips #{id}" do
        expect(round_trips?(id)).to be true
      end
    end

    it "distinguishes qualifier letters" do
      expect(parse("ITU-T Q.2931 B")).not_to eq(parse("ITU-T Q.2931 C"))
    end

    describe "the glued spelling" do
      it "parses and round-trips ITU-T D.502R (02/2026)" do
        expect(round_trips?("ITU-T D.502R (02/2026)")).to be true
      end

      it "flags the glued form so it renders back" do
        expect(parse("ITU-T D.502R").code.qualifier_glued).to be true
        expect(parse("ITU-T D.200 R").code.qualifier_glued).to be false
      end
    end

    # Code#to_s renders in grammar order — a glued suffix is captured inside
    # standard_code, a spaced one afterwards by code_suffixes. Rendering the
    # edition word unconditionally first printed "Q.11a bis" as "Q.11 bisa".
    it "renders a glued qualifier before a spaced edition word" do
      expect(round_trips?("ITU-T Q.11a bis")).to be true
    end

    describe "the lowercase glued spelling" do
      %w[ITU-T\ I.256.2a ITU-T\ I.256.2b ITU-T\ I.256.2c].each do |id|
        it "parses and round-trips #{id}" do
          expect(round_trips?("#{id} (03/1993)")).to be true
        end
      end

      it "keeps the sub-variants distinct" do
        expect(parse("ITU-T I.256.2a")).not_to eq(parse("ITU-T I.256.2b"))
      end
    end
  end

  # The qualifier rule fires on every with_series/without_series parse, so the
  # two guards that keep it from eating a following keyword are load-bearing.
  describe "the qualifier does not swallow a following keyword" do
    {
      "ITU-T A.23 Annex A (06/2014)" => Pubid::Itu::Identifiers::AnnexOfRecommendation,
      "ITU-T G.729 Annex C+ (02/2000)" => Pubid::Itu::Identifiers::AnnexOfRecommendation,
      "ITU-T G.101 App. I (05/2000)" => Pubid::Itu::Identifiers::AppendixOfRecommendation,
      "ITU-T E.156 Suppl. 2" => Pubid::Itu::Identifiers::Supplement,
      "ITU-T G.989 Amd. 1" => Pubid::Itu::Identifiers::Amendment,
      "ITU-T I.363 (1993) Add. 1" => Pubid::Itu::Identifiers::Addendum,
      "ITU-T Z.100 (1999) Cor. 1" => Pubid::Itu::Identifiers::Corrigendum,
      "ITU-T G.9701 (2014) Err. 1" => Pubid::Itu::Identifiers::Errata,
      "ITU-T H.764 V2 (11/2019)" => Pubid::Itu::Identifiers::Recommendation,
    }.each do |id, klass|
      it "still routes #{id} to #{klass.name.split('::').last}" do
        expect(parse(id)).to be_a(klass)
      end
    end
  end

  describe "URN and matching" do
    # Code#to_s may now contain a space, which is not admissible inside a URN
    # segment.
    it "emits no whitespace in a URN" do
      expect(parse("ITU-T E.250 bis (12/1972)").to_urn).not_to include(" ")
      expect(parse("ITU-T D.200 R (10/1976)").to_urn).not_to include(" ")
    end

    it "keeps the qualified and unqualified URNs distinct" do
      expect(parse("ITU-T D.200 R (10/1976)").to_urn)
        .not_to eq(parse("ITU-T D.200 (10/1976)").to_urn)
    end

    # mr_number_with_part ignored both suffixes, so every qualified variant
    # collapsed onto its base's slug — and the B/C/D/E/F variants of one
    # Recommendation onto each other.
    describe "MR strings" do
      {
        "qualifier vs none" => ["ITU-T D.200 (10/1976)", 
                                "ITU-T D.200 R (10/1976)"],
        "qualifier letters" => ["ITU-T Q.2931 B", "ITU-T Q.2931 C"],
        "edition vs none" => ["ITU-T E.250", "ITU-T E.250 bis"],
        "glued edition" => ["ITU-T X.50", "ITU-T X.50bis"],
      }.each do |label, (a, b)|
        it "distinguishes #{label}" do
          expect(parse(a).to_mr_string).not_to eq(parse(b).to_mr_string)
        end
      end

      it "leaves a suffix-less identifier's slug unchanged" do
        expect(parse("ITU-R BO.600-1").to_mr_string).to eq("itu.r.bo-600-1")
        expect(parse("ITU-T G.711").to_mr_string).to eq("itu.t.g-711")
      end
    end

    # exclude(:parts) rebuilds the Code by hand; a new attribute missing from
    # that rebuild would be silently dropped.
    it "keeps the suffixes when parts are excluded" do
      excluded = parse("ITU-T E.250 bis (12/1972)").exclude(:parts)
      expect(excluded.code.series_suffix).to eq("bis")
      expect(excluded.code.series_suffix_spaced).to be true

      excluded = parse("ITU-T D.200 R (10/1976)").exclude(:parts)
      expect(excluded.code.qualifier).to eq("R")
    end
  end

  describe "flag polarity" do
    it "does not serialize the flags for an ordinary recommendation" do
      hash = parse("ITU-T G.711 (11/1988)").to_hash

      expect(hash).not_to have_key("series_suffix_spaced")
      expect(hash).not_to have_key("qualifier")
      expect(hash).not_to have_key("qualifier_glued")
    end
  end
end
