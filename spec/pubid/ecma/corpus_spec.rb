# frozen_string_literal: true

require "spec_helper"

# Whole-corpus gate for the ECMA flavor.
#
# spec/fixtures/ecma/identifiers/pass/index_corpus.txt is the complete published
# relaton-data-ecma index (804 rows), rendered as
# "<:id:>[ ed<:ed:>][ vol<:vol:>]" — regenerate it with
# spec/fixtures/ecma/generate_index_corpus.rb.
#
# Relaton keys its index on a BARE `id.to_s`, so the whole point of carrying the
# edition and the volume is that these 804 rows key uniquely. Before that they
# collapsed onto 421 keys and 383 rows were dropped on every crawl, silently.
#
# The three identity surfaces are asserted together on purpose: an
# identity-bearing marker must reach `to_s`, `to_urn` AND `to_mr_string`, or two
# distinct documents share a URN or an output filename.
module EcmaCorpusSpec
  PATH = File.join(
    __dir__, "../../fixtures/ecma/identifiers/pass/index_corpus.txt"
  ).freeze

  # The published row count. Bump it after a re-crawl — it is a tripwire, so
  # only the "reads the whole published corpus" example should ever notice.
  EXPECTED_ROWS = 804

  REFERENCES = File.readlines(PATH).map(&:strip).reject do |line|
    line.empty? || line.start_with?("#")
  end.freeze
end

RSpec.describe "Pubid::Ecma published corpus" do
  let(:identifiers) do
    EcmaCorpusSpec::REFERENCES.map { |s| Pubid::Ecma::Identifier.parse(s) }
  end

  # A tripwire: a wrong path would otherwise make every example below vacuous.
  it "reads the whole published corpus" do
    expect(EcmaCorpusSpec::REFERENCES.size)
      .to eq(EcmaCorpusSpec::EXPECTED_ROWS)
  end

  it "parses every row and renders it back byte-exactly" do
    failures = EcmaCorpusSpec::REFERENCES.filter_map do |reference|
      rendered = Pubid::Ecma::Identifier.parse(reference).to_s
      "#{reference} => #{rendered}" unless rendered == reference
    rescue StandardError => e
      "#{reference} => #{e.class}: #{e.message}"
    end

    expect(failures).to be_empty
  end

  it "keys uniquely on to_s (the relaton index key)" do
    expect(identifiers.map(&:to_s).uniq.size)
      .to eq(EcmaCorpusSpec::REFERENCES.size)
  end

  it "keys uniquely on to_urn" do
    expect(identifiers.map { |id| id.to_urn.to_s }.uniq.size)
      .to eq(EcmaCorpusSpec::REFERENCES.size)
  end

  it "keys uniquely on to_mr_string" do
    expect(identifiers.map(&:to_mr_string).uniq.size)
      .to eq(EcmaCorpusSpec::REFERENCES.size)
  end

  # `to_slug` is used as an output filename, so the MR must stay inside the
  # charset Renderers::MrString documents.
  it "emits only filename-safe slugs" do
    expect(identifiers.map(&:to_slug).grep_v(/\A[a-z0-9._-]+\z/)).to be_empty
  end

  it "round-trips every row through the URN" do
    failures = identifiers.filter_map do |id|
      back = Pubid::Ecma::UrnParser.parse(id.to_urn).to_s
      "#{id} => #{back}" unless back == id.to_s
    end

    expect(failures).to be_empty
  end

  # The relaton index-v2 gate: a stored hash must rebuild an identical hash.
  it "round-trips every row through to_hash/from_hash" do
    failures = identifiers.filter_map do |id|
      hash = id.to_hash
      rebuilt = Pubid::Ecma::Identifier.from_hash(hash).to_hash
      "#{id}: #{rebuilt.inspect}" unless rebuilt == hash
    end

    expect(failures).to be_empty
  end

  # Stronger than the hash check above: `#matches?` is built on `==`, so a
  # parsed reference must equal the identifier rebuilt from its own index row.
  it "rebuilds an equal identifier from every row's hash" do
    failures = identifiers.reject do |id|
      Pubid::Ecma::Identifier.from_hash(id.to_hash) == id
    end

    expect(failures).to be_empty
  end

  # The bsearch narrowing key relaton uses to pick candidates.
  it "exposes a non-empty root.number for every row" do
    expect(identifiers.count { |id| id.root.number.to_s.empty? }).to eq(0)
  end
end
