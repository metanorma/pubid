# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for ASHRAE, plus the structural tripwire for the
# `number` attribute — and the regression net for 246 identifiers that used to
# parse successfully while losing the document number entirely.
#
# Relaton::Index::Type#candidates_by_number sorts and bsearches every index row
# on `id.root.number.to_s`. ASHRAE kept the document code in a `code` :string on
# the shared base and never set the inherited `number`, so all 2,103 fixture
# identifiers keyed "".
#
# WORSE, 246 of them never had a code to key on. They parsed, and rendered as
# nonsense: 160 Errata produced the identical string "ASHRAE Standard  Errata"
# (with a double space, the BIPM Declaration corruption signature) and the
# addendum forms produced "ASHRAE Standard " or "… to ASHRAE Standard -2024".
# Two independent causes, triaged over the whole corpus:
#
#   223 ids — the BUILDER. The grammar captured everything; `build_errata` and
#             the addendum builders passed the whole parse hash to
#             #extract_base_attributes, which reads parsed[:publisher] /
#             [:type] / [:code] — all nil, because the parse nests them under
#             parsed[:base]. Builder#build unwraps that at its own entry; the
#             five other call sites did not. 63 of the 223 additionally built
#             the WRONG CLASS (a bare Standard, not an Addendum), because
#             rule(:addendum) and rule(:publisher_base_addendum) had no dispatch
#             branch at all and fell through to the plain-identifier path.
#    23 ids — the GRAMMAR. rule(:code_with_year) matched the code digits but
#             never captured them: only `year_digits.as(:year)` was named, so
#             the number was consumed and discarded. The builder already read
#             `code_year_data[:code]`, so it was waiting for a value the
#             grammar never produced.
#
# COUNT THE CORPUS IN IDENTIFIERS, NOT IN FIXTURE LINES. Earlier revisions of
# this file, of the CLAUDE.md entry and of the commit message said "3,619 ids"
# and "489 recovered". Those figures counted every `!input!rendered` line in
# `pass/` as an identifier of its own, and the doubled string parses, so nothing
# rejected them. See FIXTURE_INPUTS below.
#
# `number` is declared on the LEAVES. ASHRAE's `code` sat on the shared base
# that BOTH SingleIdentifier and SupplementIdentifier inherit — the CSA
# counter-shape, where redeclaring on an inherited-from class resolves
# nondeterministically under multi-flavor load. Only meaningful under the full
# `bundle exec rake`.
#
# This file also carries ASHRAE's corpus sweep: spec/pubid/ashrae/
# fixtures_spec.rb globs "../../../fixtures/ASHRAE/..." and reports 0 examples,
# so ASHRAE has no fixture net of its own (hand-off ten-dead-fixture-specs).
module AshraeIndexKeySpec
  # The two builder-side shapes, and the grammar-side one, with the key each
  # must produce. Every entry here rendered without its number before the fix.
  RECOVERED = {
    # builder: base-wrapped errata — 160 ids, every one of which rendered the
    # identical "ASHRAE Standard  Errata"
    "ASHRAE Guideline 0-2005 Errata (September 28, 2011)" => "0",
    "ASHRAE Guideline 1-1996 Errata (July 21, 1998)" => "1",
    "ASHRAE Guideline 1.2-2019 Errata (October 21, 2019)" => "1.2",
    # builder: no dispatch branch, so an Addendum was built as a bare, empty
    # Standard — 63 ids, rendering "ASHRAE Standard "
    "ANSI/ASHRAE/IES Addendum aj to ANSI/ASHRAE/IES Standard 90.1-2022" =>
      "90.1",
    "ASHRAE Addendum e to ASHRAE Guideline 28-2016 (December 3, 2019)" => "28",
    # grammar: code_with_year never captured the code — 23 ids, which kept
    # their year and lost only the number ("… to ASHRAE Standard -2024")
    "ANSI/ASHRAE Addendum a to ANSI/ASHRAE 34-2024 (April 30, 2025)" => "34",
    "ANSI/ASHRAE/ACCA 180-2018" => "180",
    "ASHRAE Addendum r to ANSI/ASHRAE 62.1-2022 (April 30, 2025)" => "62.1",
    "ASHRAE Addenda a and b to 105-2007" => "105",
  }.freeze

  # Plain forms that already worked — they must keep working, unchanged.
  UNCHANGED = {
    "ASHRAE Standard 90.1-2019" => "90.1",
    "ASHRAE Guideline 0-2005" => "0",
    "ANSI/ASHRAE Standard 15-2019" => "15",
  }.freeze

  # Only the two single-document leaves carry a number. The five supplement
  # types have none of their own — they reach the key through #root, which
  # walks `base` to the standard they attach to.
  NUMBERED_LEAVES = %w[Standard Guideline].freeze
  SUPPLEMENTS = %w[
    Addendum Errata CombinedAddenda AddendaPackage Interpretation
  ].freeze

  # The real identifiers behind the fixture files.
  #
  # Two filters are load-bearing, and both were wrong before. The glob stops at
  # `identifiers/`, because `spec/fixtures/ashrae/SUMMARY.txt` is a generated
  # report whose 13 prose lines are not identifiers at all. And a `pass/` line
  # for a NORMALIZING parse has the shape `!input!rendered` (see
  # spec/fixtures/classify_fixtures.rb), so the input has to be split back out.
  #
  # Feeding those lines verbatim is not a harmless no-op: the ASHRAE grammar is
  # loose enough to PARSE the doubled string, so all 1,518 of them were swept as
  # if they were identifiers. That is where the inflated "3,619 ASHRAE ids" came
  # from — the real corpus is 2,103, and every one of them parses. The split
  # mirrors FixtureFileHelper#read_pass_fixture_entries, which is not on this
  # branch yet; switch to the helper once this lands on top of it.
  FIXTURE_INPUTS = Dir
    .glob(File.join(__dir__, "../../fixtures/ashrae/identifiers/**/*.txt"))
    .reject { |f| f.include?("/fail/") }
    .flat_map { |f| File.readlines(f, chomp: true) }
    .map(&:strip).reject(&:empty?).reject { |l| l.start_with?("#") }
    .map { |l| (m = l.match(/\A!(.+)!(.+)\z/)) ? m[1] : l }
    .uniq.freeze

  def self.parsed_corpus
    @parsed_corpus ||= FIXTURE_INPUTS.filter_map do |line|
      id = begin
        Pubid::Ashrae.parse(line)
      rescue StandardError, Parslet::ParseFailed
        nil
      end
      [line, id] if id
    end
  end
end

RSpec.describe "Pubid::Ashrae index key (root.number)" do
  describe "structural tripwire (full-suite only)" do
    AshraeIndexKeySpec::NUMBERED_LEAVES.each do |leaf|
      it "declares `number` as a String on #{leaf}" do
        klass = Pubid::Ashrae::Identifiers.const_get(leaf)
        expect(klass.attributes[:number].type)
          .to eq(Lutaml::Model::Type::String)
      end
    end

    AshraeIndexKeySpec::SUPPLEMENTS.each do |leaf|
      it "leaves #{leaf} without its own number attribute" do
        klass = Pubid::Ashrae::Identifiers.const_get(leaf)
        expect(klass.attributes[:number].type).to eq(Pubid::Components::Code)
      end
    end

    # SupplementIdentifier#code delegates to the base standard. Its body used
    # to be `base&.code`, and the code -> number rename left it pointing at a
    # method that no longer exists — so it raised NoMethodError on every
    # supplement. Nothing inside lib/pubid/ashrae calls it, which is exactly
    # why the suite stayed green while a public method on five types broke.
    #
    # It is deliberately still called `code`, not `number`: `number` is an
    # inherited lutaml attribute typed Components::Code, so a String-returning
    # method of that name makes to_hash raise IncorrectModelError on every
    # supplement. The to_hash assertions in the corpus sweep below are what
    # catch that.
    it "delegates #code to the base standard on every supplement" do
      id = Pubid::Ashrae.parse(
        "ASHRAE Guideline 0-2005 Errata (September 28, 2011)",
      )
      expect { id.code }.not_to raise_error
      expect(id.code).to eq("0")
      expect(id.code).to eq(id.base.number)
    end

    it "keeps to_hash working on a supplement" do
      id = Pubid::Ashrae.parse(
        "ASHRAE Guideline 0-2005 Errata (September 28, 2011)",
      )
      expect { id.to_hash }.not_to raise_error
      expect(id.to_hash).not_to have_key("number")
    end

    it "leaves the inherited-from classes' `number` untouched" do
      # ASHRAE's `code` sat here, inherited by BOTH the single-document and the
      # supplement branch. Redeclaring on these is the determinism landmine.
      [Pubid::Ashrae::Identifier, Pubid::Ashrae::SingleIdentifier,
       Pubid::Ashrae::SupplementIdentifier].each do |klass|
        expect(klass.attributes[:number].type).to eq(Pubid::Components::Code)
      end
    end
  end

  describe "identifiers that used to lose their number" do
    AshraeIndexKeySpec::RECOVERED.each do |ref, key|
      context ref do
        subject(:id) { Pubid::Ashrae.parse(ref) }

        it "keys on #{key.inspect}" do
          expect(id.root.number.to_s).to eq(key)
        end

        it "renders the number instead of dropping it" do
          expect(id.to_s).to include(key)
        end

        it "renders no double space" do
          expect(id.to_s).not_to include("  ")
        end
      end
    end
  end

  describe "forms that already worked" do
    AshraeIndexKeySpec::UNCHANGED.each do |ref, key|
      it "#{ref} still keys on #{key.inspect} and round-trips its rendering" do
        id = Pubid::Ashrae.parse(ref)
        expect(id.root.number.to_s).to eq(key)
        expect(id.to_s).to include(key)
      end
    end
  end

  # KNOWN GAP, pre-existing and deliberately not closed here. An
  # "Interpretations for …" reference builds a plain Standard and the marker is
  # lost entirely, giving an identifier IDENTICAL to the standard it interprets:
  # same class, same to_s, same hash, same slug. All 51 interpretation rows
  # already behaved this way on the main baseline, so this branch neither
  # caused nor worsened it.
  #
  # THE CAUSE IS NOT ALTERNATION ORDERING, which an earlier revision of this
  # comment claimed. rule(:interpretation_identifier) IS reached and DOES match
  # — dump the tree and you get {base: {type: "Standard", code: "15.2", year:
  # "2022"}}, with the "Interpretations for " prefix consumed. What it never
  # does is TAG itself: the rule has no `.as(:interpretation_identifier)`
  # wrapper, so Builder#build's `elsif parsed_hash[:interpretation_identifier]`
  # branch is unreachable dead code and the tree falls through to the plain
  # identifier path. Fixing it is a one-line wrap plus whatever the resulting
  # tree shape needs in the builder. See hand-off
  # ashrae-interpretation-collapses-onto-base.
  describe "interpretations still collapse onto their base standard" do
    it "builds a Standard, not an Interpretation" do
      expect(Pubid::Ashrae.parse("Interpretations for Standard 15.2-2022"))
        .to be_a(Pubid::Ashrae::Identifiers::Standard)
    end

    it "is indistinguishable from the standard it interprets" do
      interp = Pubid::Ashrae.parse("Interpretations for Standard 15.2-2022")
      plain = Pubid::Ashrae.parse("ASHRAE Standard 15.2-2022")
      expect(interp.to_hash).to eq(plain.to_hash)
      expect(interp.to_mr_string).to eq(plain.to_mr_string)
    end
  end

  # KNOWN GAP, pre-existing, and the reason the slug-distinctness sweep below
  # cannot see it. Errata#errata_date is ALWAYS nil: Builder#extract_errata_date
  # computes the month and the year and then unconditionally `return nil`
  # ("parser enhancement needed"), and rule(:errata_date) never captures the
  # month name or the day at all — only `:errata_year` is named. So two errata
  # of one standard, issued ten days apart, are one identifier on every surface.
  #
  # This branch's new Errata#mr_supplement_suffix reads errata_date, so today it
  # always emits the bare "errata". The hook is kept rather than trimmed: it is
  # correct the moment the date is captured, and the alternative is to slug
  # every erratum flat, which is what collapsed them in the first place.
  #
  # Fixing it means capturing month+day in the grammar and deciding whether the
  # date belongs in to_s — a rendering decision, not a repair. See hand-off
  # ashrae-errata-date-dropped.
  describe "two errata of one standard are still one identifier" do
    let(:first) do
      Pubid::Ashrae.parse("ASHRAE Guideline 14-2002 Errata (October 10, 2008)")
    end
    let(:second) do
      Pubid::Ashrae.parse("ASHRAE Guideline 14-2002 Errata (October 20, 2008)")
    end

    it "drops the errata date entirely" do
      expect(first.errata_date).to be_nil
    end

    it "cannot tell the two apart on any identity surface" do
      expect(first.to_s).to eq(second.to_s)
      expect(first.to_hash).to eq(second.to_hash)
      expect(first.to_urn.to_s).to eq(second.to_urn.to_s)
      expect(first.to_mr_string).to eq(second.to_mr_string)
    end
  end

  describe "the whole fixture corpus" do
    # Every fixture input outside `fail/` parses, so the two counts are equal.
    # Asserting equality rather than a floor is what makes a silently shrinking
    # corpus — a bad glob, a marker-splitting regression — fail loudly here.
    it "sweeps every fixture identifier, and all of them parse" do
      expect(AshraeIndexKeySpec.parsed_corpus.size)
        .to eq(AshraeIndexKeySpec::FIXTURE_INPUTS.size)
      expect(AshraeIndexKeySpec.parsed_corpus.size).to be >= 2_103
    end

    it "gives every identifier a non-empty root.number" do
      bad = AshraeIndexKeySpec.parsed_corpus.select do |_, id|
        id.root.number.to_s.empty?
      end
      expect(bad.map(&:first).first(10)).to eq([])
    end

    # 160 Errata all rendered as the identical "ASHRAE Standard  Errata".
    it "never renders a double space" do
      bad = AshraeIndexKeySpec.parsed_corpus.select do |_, id|
        id.to_s.include?("  ")
      end
      expect(bad.map(&:first).first(10)).to eq([])
    end

    it "always renders at least one digit" do
      bad = AshraeIndexKeySpec.parsed_corpus.reject do |_, id|
        id.to_s.match?(/\d/)
      end
      expect(bad.map(&:first).first(10)).to eq([])
    end

    it "round-trips every identifier through from_hash(to_hash)" do
      bad = AshraeIndexKeySpec.parsed_corpus.reject do |_, id|
        h = id.to_hash
        Pubid::Ashrae::Identifier.from_hash(h).to_hash == h
      end
      expect(bad.map(&:first).first(10)).to eq([])
    end

    # to_slug is an output FILENAME. Before this change ALL 2,103 ids shared the
    # single slug "ashrae" — the worst collapse measured in the gem.
    it "gives every identifier a non-empty, filename-safe MR slug" do
      slugs = AshraeIndexKeySpec.parsed_corpus.map { |_, id| id.to_mr_string }
      expect(slugs.count(&:empty?)).to eq(0)
      expect(slugs.grep(/[^a-z0-9._-]/).first(5)).to eq([])
    end

    it "gives distinct identifiers distinct slugs" do
      by_slug = AshraeIndexKeySpec.parsed_corpus
        .group_by { |_, id| id.to_mr_string }
      clashing = by_slug.reject do |_, rows|
        rows.map { |_, id| id.to_hash }.uniq.size == 1
      end
      expect(clashing.keys.first(5)).to eq([])
    end
  end
end
