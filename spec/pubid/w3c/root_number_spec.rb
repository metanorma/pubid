# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for W3C, plus the structural tripwire for the
# `number` attribute.
#
# Relaton::Index::Type#candidates_by_number sorts and bsearches every index row
# on `id.root.number.to_s`. W3C keeps its document slug in `number`, so every
# W3C row keys on that slug; an empty key silently degrades the binary search to
# a linear scan over the whole index — no error, just a slow, wrong-shaped
# lookup. Every W3C identifier is its own root (the flavor has no supplement or
# wrapper type), so this reader is always the key.
#
# IMPORTANT: the structural block below is only meaningful under the FULL suite
# (`bundle exec rake`), never `rspec spec/pubid/w3c` alone. `number` is declared
# `:string` on Pubid::W3c::Identifier, overriding the parent
# ::Pubid::Identifier's `attribute :number, Components::Code`. lutaml's
# `inherited` hook deep-dups the parent's attribute table into each subclass at
# class-definition time (serialize/initialization.rb#initialize_attrs), so a
# leaf holds a SNAPSHOT, not a live view. That is safe here because W3C's base
# is one file with one class body that is never reopened, and Ruby resolves the
# superclass constant — running that body to completion — before opening any
# leaf body. Split the base across two files the way IEEE does and a leaf can
# snapshot a half-built base, silently reverting `number` to Components::Code.
module W3cIndexKeySpec
  # One entry per identifier type: printed reference => [leaf class, slug].
  KEYS = {
    "W3C 2dcontext" => ["Standard", "2dcontext"],
    "W3C NOTE-xml-names" => ["Note", "xml-names"],
    "W3C DNOTE-webcodecs-flac-codec-registration-20240419" =>
      ["DraftNote", "webcodecs-flac-codec-registration"],
    "W3C WD-charmod-19991129" => ["WorkingDraft", "charmod"],
    "W3C CR-exi-20091208" => ["CandidateRecommendation", "exi"],
    "W3C CRD-accelerometer-20250212" =>
      ["CandidateRecommendationDraft", "accelerometer"],
    "W3C REC-ATAG10-20000203" => ["Recommendation", "ATAG10"],
    "W3C PR-CSS1" => ["ProposedRecommendation", "CSS1"],
    "W3C PER-rif-dtb-20121211" =>
      ["ProposedEditedRecommendation", "rif-dtb"],
    "W3C SPSD-2dcontext-20210128" =>
      ["SupersededRecommendation", "2dcontext"],
    "W3C OBSL-widgets-apis-20181011" =>
      ["ObsoleteRecommendation", "widgets-apis"],
  }.freeze

  LEAVES = KEYS.values.map(&:first).freeze

  # The four real `suff` shapes in the published relaton-data-w3c corpus. Their
  # "/" tail — and any date preceding it — is folded into the slug, so such a
  # row keys under its own bucket rather than the base document's. Pinned so the
  # behaviour is visible, not because it is desirable.
  SUFF = {
    "W3C REC-CSS2-19980512/fonts" => "CSS2-19980512/fonts",
    "W3C WCA-terms/01" => "WCA-terms/01",
    "W3C 9605-Indexing-Workshop/ReportOutcomes" =>
      "9605-Indexing-Workshop/ReportOutcomes",
    "W3C WD-DOM-19980416/requirements" => "DOM-19980416/requirements",
  }.freeze
end

RSpec.describe "Pubid::W3c index key (root.number)" do
  def parse(str)
    Pubid::W3c::Identifier.parse(str)
  end

  # The structural half. The examples below prove the *effect* (a String slug),
  # but would still pass if a leaf had snapshotted the parent's
  # Components::Code — that failure is load-order dependent. These assertions
  # read the attribute definitions directly, so they fail immediately.
  describe "number resolves to a plain string everywhere" do
    it "is declared :string on the shared base" do
      expect(Pubid::W3c::Identifier.attributes[:number].type)
        .to eq(Lutaml::Model::Type::String)
    end

    W3cIndexKeySpec::LEAVES.each do |leaf|
      it "reaches Identifiers::#{leaf} as :string, not Components::Code" do
        klass = Pubid::W3c::Identifiers.const_get(leaf)
        expect(klass.attributes[:number].type)
          .to eq(Lutaml::Model::Type::String)
      end
    end

    it "no longer exposes the historical `code` name" do
      expect(parse("W3C 2dcontext")).not_to respond_to(:code)
    end
  end

  W3cIndexKeySpec::KEYS.each do |ref, (leaf, slug)|
    context ref do
      let(:parsed) { parse(ref) }

      it "builds Identifiers::#{leaf}" do
        expect(parsed).to be_a(Pubid::W3c::Identifiers.const_get(leaf))
      end

      it "keys on #{slug.inspect} at the root" do
        expect(parsed.root.number.to_s).to eq(slug)
      end

      it "keys non-empty for Relaton::Index" do
        expect(parsed.root.number.to_s).not_to be_empty
      end

      it "is its own root" do
        expect(parsed.root).to be(parsed)
      end

      it "survives a from_hash round-trip with the key intact" do
        rebuilt = Pubid::W3c::Identifier.from_hash(parsed.to_hash)
        expect(rebuilt.root.number).to eq(parsed.root.number)
      end
    end
  end

  describe "serialized shape" do
    it "stores the slug under `number`, with the date when present" do
      expect(parse("W3C REC-ATAG10-20000203").to_hash)
        .to eq("_type" => "pubid:w3c:recommendation",
               "number" => "ATAG10",
               "date" => "20000203")
    end

    it "omits `date` for a date-less identifier" do
      expect(parse("W3C NOTE-xml-names").to_hash)
        .to eq("_type" => "pubid:w3c:note", "number" => "xml-names")
    end
  end

  describe "clustering" do
    it "puts every maturity level of one document in one bucket" do
      keys = ["W3C WD-DOM-19980416", "W3C REC-DOM-19981001", "W3C DOM"]
        .map { |ref| parse(ref).root.number.to_s }

      expect(keys).to all(eq("DOM"))
    end
  end

  describe "corpus `suff` shapes" do
    W3cIndexKeySpec::SUFF.each do |ref, slug|
      it "keys #{ref} on #{slug.inspect}" do
        parsed = parse(ref)
        expect(parsed.root.number.to_s).to eq(slug)
        expect(parsed.to_s).to eq(ref)
      end
    end
  end
end
