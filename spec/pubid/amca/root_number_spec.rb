# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for AMCA, plus the structural tripwire for the
# `number` attribute.
#
# Relaton::Index::Type#candidates_by_number sorts and bsearches every index row
# on `id.root.number.to_s`. AMCA declared its own `code` attribute and never set
# the `number` it inherits from ::Pubid::Identifier, so all 46 parseable fixture
# ids keyed the empty string "" and the binary search degraded to a linear scan.
#
# `number` and `year` are both plain :string columns declared on the LEAVES.
# The shared Pubid::Amca::Identifier keeps the inherited Components::Code
# `number` untouched — redeclaring there is the multi-flavor determinism
# landmine, since all three leaves inherit from it. The tripwire below asserts
# both halves and is only meaningful under the full `bundle exec rake`.
#
# `year` is a string for a reason worth remembering: it used to be declared
# Components::Date, but the builder assigns a String and lutaml does not cast
# it, so the PARSE path held a String while from_hash produced a
# Components::Date. `to_hash` and `to_s` agreed (the old converters normalised
# both shapes), so the relaton index gate never noticed — but `==`, and
# therefore `#matches?`, was false for every AMCA id.
#
# This file also carries AMCA's corpus sweep: spec/pubid/amca/fixtures_spec.rb
# globs "../../../fixtures/AMCA/..." (one ".." too many AND an uppercase
# directory) and reports 0 examples, so AMCA has no fixture net of its own.
# See HANDOFFS/metanorma__pubid__ten-dead-fixture-specs.md.
module AmcaIndexKeySpec
  # printed reference => [leaf class, index key]
  KEYS = {
    "ANSI/AMCA 210-16 /ASHRAE 51-16" => ["Standard", "210"],
    "ANSI/AMCA 220-21" => ["Standard", "220"],
    "AMCA Publication 211-22 (Rev. 01-23)" => ["Publication", "211"],
    "AMCA Publication 311-16" => ["Publication", "311"],
    "AMCA 99 JW Interp" => ["Interpretation", "99"],
    "AMCA 99 KB Interp" => ["Interpretation", "99"],
  }.freeze

  LEAVES = %w[Standard Publication Interpretation].freeze

  FIXTURE_LINES = Dir
    .glob(File.join(__dir__, "../../fixtures/amca/**/*.txt"))
    .reject { |f| f.include?("/fail/") }
    .flat_map { |f| File.readlines(f, chomp: true) }
    .map(&:strip).reject(&:empty?).reject { |l| l.start_with?("#") }
    .uniq.freeze

  def self.parsed_corpus
    @parsed_corpus ||= FIXTURE_LINES.filter_map do |line|
      id = begin
        Pubid::Amca.parse(line)
      rescue StandardError, Parslet::ParseFailed
        nil
      end
      [line, id] if id
    end
  end
end

RSpec.describe "Pubid::Amca index key (root.number)" do
  describe "structural tripwire (full-suite only)" do
    it "declares no `code` attribute anywhere" do
      expect(Pubid::Amca::Identifier.attributes).not_to have_key(:code)
      AmcaIndexKeySpec::LEAVES.each do |leaf|
        expect(Pubid::Amca::Identifiers.const_get(leaf).attributes)
          .not_to have_key(:code)
      end
    end

    it "declares `number` as a String on every LEAF" do
      AmcaIndexKeySpec::LEAVES.each do |leaf|
        expect(Pubid::Amca::Identifiers.const_get(leaf).attributes[:number].type)
          .to eq(Lutaml::Model::Type::String)
      end
    end

    it "leaves the shared base's inherited `number` untouched" do
      # A redeclaration here is the determinism landmine: all three leaves
      # inherit from this class.
      expect(Pubid::Amca::Identifier.attributes[:number].type)
        .to eq(Pubid::Components::Code)
    end
  end

  describe "per-type index key" do
    AmcaIndexKeySpec::KEYS.each do |ref, (klass, key)|
      context ref do
        subject(:id) { Pubid::Amca.parse(ref) }

        it "is a #{klass}" do
          expect(id.class.name.split("::").last).to eq(klass)
        end

        it "keys on #{key.inspect}" do
          expect(id.root.number.to_s).to eq(key)
        end
      end
    end
  end

  # Publication and Interpretation carried hand-written keyword initializers
  # that assigned ivars directly, bypassing lutaml. Three consequences: no
  # `_type` was emitted (so from_hash could not route back to the concrete
  # class), the `publisher` default never materialised, and `revision` /
  # `interpretation_code` were plain attr_readers that to_hash dropped. The
  # AIEE/IRE/NESC migration removed exactly this construct.
  describe "Publication and Interpretation serialize like Standard" do
    {
      "AMCA Publication 211-22 (Rev. 01-23)" => "pubid:amca:publication",
      "AMCA 99 JW Interp" => "pubid:amca:interpretation",
    }.each do |ref, type|
      it "#{ref} emits _type #{type}" do
        expect(Pubid::Amca.parse(ref).to_hash["_type"]).to eq(type)
      end

      it "#{ref} routes back through from_hash" do
        id = Pubid::Amca.parse(ref)
        back = Pubid::Amca::Identifier.from_hash(id.to_hash)
        expect(back.class).to eq(id.class)
        expect(back.to_hash).to eq(id.to_hash)
      end
    end

    # KNOWN GAP, pre-existing and deliberately not fixed here. The grammar
    # captures the revision as a top-level `revision_year` on the publication
    # node, but Builder#build_publication looks for it nested under
    # `parsed[:revision][:revision_year]`, so it never reaches the object — and
    # the grammar only captures "01" of "Rev. 01-23" anyway. `revision` is a
    # real attribute now (it was a to_hash-invisible attr_reader), so it will
    # carry data the moment the builder is fixed. Pinned so the gap stays
    # visible. See hand-off asme-bpvc-and-amca-residue.
    it "does not yet populate the publication revision" do
      expect(Pubid::Amca.parse("AMCA Publication 211-22 (Rev. 01-23)")
        .revision).to be_nil
    end

    it "keeps the interpretation code" do
      expect(Pubid::Amca.parse("AMCA 99 JW Interp")
        .interpretation_code).to eq("JW")
    end
  end

  describe "the whole fixture corpus" do
    it "parses a corpus worth sweeping" do
      expect(AmcaIndexKeySpec.parsed_corpus.size).to be >= 46
    end

    it "gives every identifier a non-empty root.number" do
      bad = AmcaIndexKeySpec.parsed_corpus.select do |_, id|
        id.root.number.to_s.empty?
      end
      expect(bad.map(&:first)).to eq([])
    end

    it "round-trips every identifier through from_hash(to_hash)" do
      bad = AmcaIndexKeySpec.parsed_corpus.select do |_, id|
        h = id.to_hash
        Pubid::Amca::Identifier.from_hash(h).to_hash != h
      end
      expect(bad.map(&:first)).to eq([])
    end

    # Stronger than the hash round-trip above, and it used to FAIL for every
    # AMCA id. `year` was declared Components::Date but the builder assigns a
    # String and lutaml does not cast it, so the parse path held a String while
    # from_hash produced a Components::Date. `to_hash` and `to_s` agreed — the
    # converters normalised both shapes to a scalar — so the relaton index gate
    # (`from_hash(to_hash) == to_hash`) never caught it, while `==`, and
    # therefore `#matches?`, was broken. Both `number` and `year` are plain
    # strings now and the converters are gone.
    it "equals its own round-trip, not just its hash" do
      bad = AmcaIndexKeySpec.parsed_corpus.reject do |_, id|
        id == Pubid::Amca::Identifier.from_hash(id.to_hash)
      end
      expect(bad.map(&:first)).to eq([])
    end

    # to_slug is an output FILENAME. Before the index columns landed, all 46
    # ids collapsed onto two slugs ("amca" x31 and "" x15).
    #
    # The corpus contains genuine duplicate spellings of one document
    # ("ANSI/AMCA 220-21" and "ANSI/AMCA Standard 220-21" have identical
    # hashes), so the target is one slug per DISTINCT IDENTIFIER, not one per
    # input line.
    it "gives every identifier a non-empty, filename-safe MR slug" do
      slugs = AmcaIndexKeySpec.parsed_corpus.map { |_, id| id.to_mr_string }
      expect(slugs.count(&:empty?)).to eq(0)
      expect(slugs.grep(/[^a-z0-9._-]/)).to eq([])
    end

    it "gives distinct identifiers distinct slugs" do
      by_slug = AmcaIndexKeySpec.parsed_corpus.group_by do |_, id|
        id.to_mr_string
      end
      clashing = by_slug.reject do |_, rows|
        rows.map { |_, id| id.to_hash }.uniq.size == 1
      end
      expect(clashing.keys).to eq([])
    end
  end
end
