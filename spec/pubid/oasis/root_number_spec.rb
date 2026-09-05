# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for OASIS, plus the structural tripwire for the
# `number` attribute and the MR slug it feeds.
#
# Relaton::Index::Type#candidates_by_number sorts and bsearches every index row
# on `id.root.number.to_s`. OASIS kept the specification name in a bespoke
# `spec` attribute and never set the `number` it inherits from
# ::Pubid::Identifier, so all 605 rows of relaton-data-oasis shared the empty
# key "" and the binary search degraded to a linear scan, silently.
#
# `to_mr_string` was worse: "" for every identifier, and `to_slug` delegates to
# it, so every OASIS document shared one output FILENAME.
#
# IMPORTANT: the structural block is only meaningful under the FULL suite
# (`bundle exec rake`), never `rspec spec/pubid/oasis` alone. `attribute
# :number, :string` retypes the parent's Components::Code — the multi-flavor
# determinism landmine recorded in CLAUDE.md for IEEE/IETF/IANA/CIE. It is safe
# on the base only because this class body lives in ONE file and is never
# reopened, so lutaml has finished the attribute table before
# Identifiers::Standard snapshots it (the W3C precedent).
module OasisIndexKeySpec
  # printed reference => index key (the specification name)
  KEYS = {
    # bare specification name
    "OASIS amqp-core" => "amqp-core",
    "OASIS EDXL" => "EDXL",
    # name + version: the version is a sibling, so every version of one
    # specification shares the bucket
    "OASIS WSDM-v1.1" => "WSDM",
    "OASIS ebxml-bp-v2.0.4" => "ebxml-bp",
    # name + version + part
    "OASIS amqp-core-overview-v1.0-Pt0" => "amqp-core-overview",
    # name + version + stage + part
    "OASIS OSLC-CoreShapes-3.0-PS01-Pt8" => "OSLC-CoreShapes",
    # part before stage
    "OASIS OSLC-AM-3.0-Part1-PS01" => "OSLC-AM",
    # trailing label
    "OASIS AkomaNtosoCore-v1.0-Pt2-Specifications" => "AkomaNtosoCore",
    # malformed record: nothing after the name classifies, so the whole
    # remainder stays in the name. The key is non-empty, which is the contract.
    "OASIS CTAS-v3.0]-PS01" => "CTAS-v3.0]",
  }.freeze

  FIXTURE_LINES = Dir
    .glob(File.join(__dir__, "../../fixtures/oasis/identifiers/pass/*.txt"))
    .flat_map { |f| File.readlines(f, chomp: true) }
    .map(&:strip).reject(&:empty?).reject { |l| l.start_with?("#") }
    .uniq.freeze

  def self.parsed_corpus
    @parsed_corpus ||= FIXTURE_LINES.filter_map do |line|
      id = begin
        Pubid::Oasis.parse(line)
      rescue StandardError, Parslet::ParseFailed
        nil
      end
      [line, id] if id
    end
  end
end

RSpec.describe "Pubid::Oasis index key (root.number)" do
  describe "structural tripwire (full-suite only)" do
    it "declares `number` as a String on the base" do
      expect(Pubid::Oasis::Identifier.attributes[:number].type)
        .to eq(Lutaml::Model::Type::String)
    end

    it "resolves `number` to a String on the sole leaf too" do
      expect(Pubid::Oasis::Identifiers::Standard.attributes[:number].type)
        .to eq(Lutaml::Model::Type::String)
    end

    it "no longer declares a `spec` attribute" do
      expect(Pubid::Oasis::Identifier.attributes).not_to have_key(:spec)
      expect(Pubid::Oasis::Identifiers::Standard.attributes)
        .not_to have_key(:spec)
    end

    it "drops `spec` entirely, attribute and reader alike" do
      id = Pubid::Oasis.parse("OASIS OSLC-CoreShapes-3.0-PS01-Pt8")
      expect(id).not_to respond_to(:spec)
      expect(id.to_hash).not_to have_key("spec")
    end
  end

  describe "per-reference index key" do
    OasisIndexKeySpec::KEYS.each do |ref, key|
      context ref do
        subject(:id) { Pubid::Oasis.parse(ref) }

        it "keys on #{key.inspect}" do
          expect(id.root.number.to_s).to eq(key)
        end
      end
    end
  end

  describe "the whole fixture corpus" do
    it "parses a corpus worth sweeping" do
      expect(OasisIndexKeySpec.parsed_corpus.size).to be > 40
    end

    it "gives every identifier a non-empty root.number" do
      bad = OasisIndexKeySpec.parsed_corpus.select do |_, id|
        id.root.number.to_s.empty?
      end
      expect(bad.map(&:first).first(10)).to eq([])
    end

    it "round-trips every identifier through from_hash(to_hash)" do
      bad = OasisIndexKeySpec.parsed_corpus.reject do |_, id|
        Pubid::Oasis::Identifier.from_hash(id.to_hash) == id
      end
      expect(bad.map(&:first).first(10)).to eq([])
    end

    it "renders every identifier back verbatim" do
      bad = OasisIndexKeySpec.parsed_corpus
        .reject { |line, id| id.to_s == line }
      expect(bad.map(&:first).first(10)).to eq([])
    end

    # A plain == must stay exact: the decomposition loses fragment order and
    # drops repeated fragments, so it is not by itself an identity.
    it "leaves no two distinct identifiers equal" do
      ids = OasisIndexKeySpec.parsed_corpus.map(&:last)
      equal = ids.combination(2).select { |a, b| a == b }
      expect(equal.size).to eq(0)
    end
  end

  # to_slug delegates to to_mr_string and consumers use it as an output
  # FILENAME. Before this, all 605 published rows shared the slug "".
  describe "MR slug" do
    it "carries the publisher and the whole verbatim slug" do
      expect(Pubid::Oasis.parse("OASIS OSLC-CoreShapes-3.0-PS01-Pt8")
        .to_mr_string).to eq("oasis.oslc-coreshapes-3-0-ps01-pt8")
    end

    it "keeps a bare specification name intact" do
      expect(Pubid::Oasis.parse("OASIS amqp-core").to_mr_string)
        .to eq("oasis.amqp-core")
    end

    it "sanitizes a malformed record by charset" do
      expect(Pubid::Oasis.parse("OASIS CTAS-v3.0]-PS01").to_mr_string)
        .to eq("oasis.ctas-v3-0-ps01")
    end

    it "gives every fixture identifier a distinct, filename-safe slug" do
      slugs = OasisIndexKeySpec.parsed_corpus.map { |_, id| id.to_mr_string }
      expect(slugs.uniq.size).to eq(slugs.size)
      expect(slugs.grep_v(/\A[a-z0-9._-]+\z/)).to eq([])
    end
  end
end
