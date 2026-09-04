# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for IEEE's MULTI-DESIGNATION WRAPPERS.
#
# spec/pubid/ieee/root_number_spec.rb covers the single-document leaves, which
# get their key from the Identifiers::CodeNumber mixin. That mixin is on the
# leaves only, so every wrapper that names a document by TWO designations was
# its own #root, carried no `code`, and keyed "" — 99 fixture ids, and the
# existing spec made them read as covered.
#
# Four of the five are pure #root gaps: the number is already there, on a
# nested identifier, and #root simply never walked to it. Each walks to the
# IEEE half, which is the designation IEEE itself files the document under.
#
# The fifth, MultiNumberedIdentifier, was a data-loss bug of the CSA container
# class: it held its two members in `attr_accessor`s, which lutaml cannot see,
# so `to_hash` was {"_type" => ...} and nothing else.
module IeeeWrapperKeySpec
  WRAPPER_CLASSES = %w[
    AdoptedStandard DualPublished CsaDualPublished
    InterpretationIdentifier MultiNumberedIdentifier
  ].freeze

  FIXTURE_LINES = Dir
    .glob(File.join(__dir__, "../../fixtures/ieee/**/*.txt"))
    .reject { |f| f.include?("/fail/") }
    .flat_map { |f| File.readlines(f, chomp: true) }
    .map(&:strip).reject(&:empty?).reject { |l| l.start_with?("#") }
    .uniq.freeze

  def self.parsed_corpus
    @parsed_corpus ||= FIXTURE_LINES.filter_map do |line|
      id = begin
        Pubid::Ieee.parse(line)
      rescue StandardError, Parslet::ParseFailed
        nil
      end
      [line, id] if id
    end
  end

  def self.wrapper_rows
    @wrapper_rows ||= parsed_corpus.select do |_, id|
      WRAPPER_CLASSES.include?(id.class.name.split("::").last)
    end
  end
end

RSpec.describe "Pubid::Ieee wrapper index keys (root.number)" do
  describe "wrappers walk #root to the IEEE designation" do
    {
      "IEEE Std 159-1972 (52 IRE 7 S2)" => "159",
      "IEEE Std 175-1960 (60 IRE 13 S1)" => "175",
      "IEEE Std 120-1955; ASME PTC 19.6-1955" => "120",
      "IEEE Std 309-1999: ANSI N42.3-1999" => "309",
      "IEEE Std 844.1-2017/CSA C22.2 No. 293.1-17" => "844",
      "IEEE Std 844.2-2017/CSA C293.2-17" => "844",
    }.each do |ref, key|
      it "#{ref} keys on #{key.inspect}" do
        expect(Pubid::Ieee.parse(ref).root.number.to_s).to eq(key)
      end
    end
  end

  # A derived attribute must not be serialized. `publisher` (and, on
  # MultiNumberedIdentifier, `year`) is computed from the member identifiers,
  # so it is default-omitted on the parse path but RE-EMITTED once from_hash
  # materializes the attribute default — an asymmetry that fails
  # `from_hash(to_hash) == to_hash`, the gate relaton's index build uses to
  # decide whether to keep a document at all.
  #
  # All 25 DualPublished ids failed it, and the re-emitted value was the
  # literal string `["IEEE", "IEEE"]` — the same Array leak as the slug. The
  # remedy is the one AdoptedStandard and JointDevelopment already use: drop
  # the derived key in `to_hash`.
  describe "derived attributes are not serialized" do
    {
      "IEEE Std 120-1955; ASME PTC 19.6-1955" => %w[publisher],
      "IEEE Std 960-1989, Std 1177-1989" => %w[publisher],
      "IEEE Std 1299/C62.22.1-1 996" => %w[publisher year],
    }.each do |ref, dropped|
      context ref do
        subject(:id) { Pubid::Ieee.parse(ref) }

        dropped.each do |key|
          it "omits the derived #{key}" do
            expect(id.to_hash).not_to have_key(key)
          end
        end

        it "round-trips through from_hash(to_hash)" do
          h = id.to_hash
          expect(Pubid::Ieee::Identifier.from_hash(h).to_hash).to eq(h)
        end
      end
    end

    # The corpus cannot reach this: every MultiNumberedIdentifier fixture has
    # an IEEE-published, year-less primary, so both derived values match their
    # defaults and are dropped whatever `to_hash` does. Build the case the
    # class's own comment says is possible.
    it "round-trips a wrapper whose member belongs to another body" do
      wrapper = Pubid::Ieee::Identifiers::MultiNumberedIdentifier.new(
        primary_identifier: Pubid::Ieee.parse("AIEE No 15-1944"),
        secondary_identifier: Pubid::Ieee.parse("IEEE Std 1177-1989"),
      )
      h = wrapper.to_hash
      expect(h).not_to have_key("publisher")
      expect(h).not_to have_key("year")
      expect(Pubid::Ieee::Identifier.from_hash(h).to_hash).to eq(h)
    end
  end

  # A dual-published document is one document under two designations, so both
  # publishers belong in the slug. `Identifier#mr_publisher` is
  # `publisher&.to_s&.downcase`, and DualPublished#publisher returns an ARRAY —
  # so the slug literally contained a Ruby array literal, brackets, quotes,
  # comma and space included, and to_slug is an output FILENAME.
  describe "DualPublished MR slug" do
    subject(:slug) do
      Pubid::Ieee.parse("IEEE Std 120-1955; ASME PTC 19.6-1955").to_mr_string
    end

    it "does not leak a Ruby array literal into the filename" do
      expect(slug).not_to include("[")
      expect(slug).not_to include("\"")
    end

    it "stays inside the documented MR charset" do
      expect(slug).to match(/\A[a-z0-9._-]+\z/)
    end

    it "names both publishers" do
      expect(slug).to include("ieee")
      expect(slug).to include("asme")
    end
  end

  # The CSA container defect: members in attr_accessors are invisible to
  # to_hash, from_hash and #exclude, so the whole identity was dropped.
  describe "MultiNumberedIdentifier" do
    subject(:id) { Pubid::Ieee.parse("IEEE Std 1299/C62.22.1-1 996") }

    it "keys on the primary designation" do
      expect(id.root.number.to_s).to eq("1299")
    end

    it "serializes both designations" do
      h = id.to_hash
      expect(h).to have_key("primary_identifier")
      expect(h).to have_key("secondary_identifier")
    end

    it "round-trips through from_hash(to_hash)" do
      h = id.to_hash
      expect(Pubid::Ieee::Identifier.from_hash(h).to_hash).to eq(h)
    end

    # On main this rendered as the EMPTY STRING — the attr_accessor members
    # were invisible, so there was nothing to render. The fixture's own "1 996"
    # carries a stray space, which pubid normalises away; what matters is that
    # the cross-reference now prints as one reference with a bare second
    # designation after the slash, not " and IEEE Std /C62.22.1-1996".
    it "renders the cross-reference instead of nothing" do
      expect(id.to_s).to eq("IEEE Std 1299/C62.22.1-1996")
    end
  end

  # An interpretation with a TRAILING DATE parses flat, which used to skip the
  # supplement builder entirely: no base, and the number, part and publisher
  # were all dropped, so "IEEE Std 1003.2-1992/INT, Dec. 1994 Ed." rendered as
  # " 1003.2-1992/INT" — a leading space where the publisher should be, the
  # BIPM Declaration corruption signature.
  describe "InterpretationIdentifier built from a flat parse" do
    {
      "IEEE Std 1003.2-1992/INT, Dec. 1994 Ed." => "IEEE Std 1003.2-1992/INT-1994",
      "IEEE Std 1003.2-1992/INT, March 1994 Edition" => "IEEE Std 1003.2-1992/INT-1994",
      "IEEE Std 1003.5-1992/INT Mar 1994" => "IEEE Std 1003.5-1992/INT-1994",
    }.each do |ref, rendered|
      context ref do
        subject(:id) { Pubid::Ieee.parse(ref) }

        it "keys on the interpreted standard's number" do
          expect(id.root.number.to_s).to eq("1003")
        end

        it "attaches the interpreted standard as its base" do
          expect(id.base).to be_a(Pubid::Ieee::Identifiers::Standard)
        end

        it "renders as #{rendered.inspect}" do
          expect(id.to_s).to eq(rendered)
        end

        it "keeps the interpretation date on the wrapper, not the base" do
          expect(id.year).to eq("1994")
          expect(id.base.year).to eq("1992")
        end
      end
    end
  end

  describe "the whole fixture corpus" do
    it "parses a corpus worth sweeping" do
      expect(IeeeWrapperKeySpec.parsed_corpus.size).to be >= 8_000
    end

    it "gives every identifier a non-empty root.number" do
      bad = IeeeWrapperKeySpec.parsed_corpus.select do |_, id|
        id.root.number.to_s.empty?
      end
      expect(bad.map(&:first).first(10)).to eq([])
    end

    it "finds the wrappers in the corpus" do
      expect(IeeeWrapperKeySpec.wrapper_rows.size).to be >= 90
    end

    # The charset is asserted MINUS the slash. A copublished IEEE identifier
    # slugs its publisher as "ansi/ieee", which is outside the documented
    # [a-z0-9._-] charset and is a filename hazard — but it is pre-existing on
    # main, affects 325 IEEE ids of every type rather than the wrappers, and
    # fixing it moves 325 published slugs. See hand-off ieee-mr-slug-residue.
    # Everything this branch touches IS asserted: no array literal, no quote,
    # no space, no uppercase.
    it "keeps wrapper slugs in charset, bar the known publisher slash" do
      bad = IeeeWrapperKeySpec.wrapper_rows.reject do |_, id|
        id.to_mr_string.match?(%r{\A[a-z0-9._/-]+\z})
      end
      expect(bad.map(&:first).first(10)).to eq([])
    end

    it "leaks no array, quote, space or uppercase into a wrapper slug" do
      bad = IeeeWrapperKeySpec.wrapper_rows.select do |_, id|
        id.to_mr_string.match?(/[\[\]"' ]|[A-Z]/)
      end
      expect(bad.map(&:first).first(10)).to eq([])
    end

    # to_slug is an output FILENAME. On main all 66 AdoptedStandard ids shared
    # 5 slugs and 5 URNs, so 66 documents overwrote each other.
    it "gives distinct wrappers distinct MR slugs" do
      by_slug = IeeeWrapperKeySpec.wrapper_rows.group_by do |_, id|
        id.to_mr_string
      end
      clashing = by_slug.reject do |_, rows|
        rows.map { |_, id| id.to_s }.uniq.size == 1
      end
      expect(clashing.keys.first(5)).to eq([])
    end

    it "gives distinct wrappers distinct URNs" do
      by_urn = IeeeWrapperKeySpec.wrapper_rows.group_by { |_, id| id.to_urn }
      clashing = by_urn.reject do |_, rows|
        rows.map { |_, id| id.to_s }.uniq.size == 1
      end
      expect(clashing.keys.first(5)).to eq([])
    end

    it "never leaks a Ruby array literal into a wrapper URN" do
      bad = IeeeWrapperKeySpec.wrapper_rows.select do |_, id|
        id.to_urn.include?("[")
      end
      expect(bad.map(&:first).first(5)).to eq([])
    end
  end
end
