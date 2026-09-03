# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for ASTM, plus the structural tripwire for the
# `number` attribute.
#
# Relaton::Index::Type#candidates_by_number sorts and bsearches every index row
# on `id.root.number.to_s`. ASTM kept identity in an Astm::Components::Code
# under a `code` attribute and never set the `number` it inherits from
# ::Pubid::Identifier, so all 248 parseable fixture ids keyed "".
#
# Astm::Components::Code is NOT a subclass of Pubid::Components::Code, so naming
# the attribute `number` retypes the inherited one — the multi-flavor
# determinism landmine. Identifiers::CodeNumber therefore declares the columns
# on every CONCRETE class and never on SingleIdentifier or Identifiers::Base.
# Note Standard AND IsoDualPublished both include it although the latter
# inherits the former: a class that is inherited from must still declare the
# columns so its subclass holds its own snapshot. Only meaningful under the
# full `bundle exec rake`.
#
# Carries ASTM's corpus sweep too: spec/pubid/astm/fixtures_spec.rb globs
# "../../../fixtures/ASTM/..." and reports 0 examples (hand-off
# ten-dead-fixture-specs).
module AstmIndexKeySpec
  # printed reference => [leaf class, bare index key]
  KEYS = {
    "ASTM E2938-15(2023)" => ["Standard", "2938"],
    "ASTM D2148-22" => ["Standard", "2148"],
    "ASTM MNL1-9TH-EB" => ["Manual", "1"],
    "ASTM RR:A01-1001" => ["ResearchReport", "1001"],
    "ASTM DS4B-EB" => ["DataSeries", "4"],
    "ASTM MONO1-EB" => ["Monograph", "1"],
    "ASTM WK91249" => ["WorkInProgress", "91249"],
    "ASTM 52303-24e1" => ["IsoDualPublished", "52303"],
    # An adjunct has no code at all: its whole identity is the designation,
    # so the designation IS the number (the IANA/IETF slug reasoning).
    "ASTM ADJD2148" => ["Adjunct", "D2148"],
  }.freeze

  CONCRETE = %w[
    Standard IsoDualPublished Manual ResearchReport DataSeries
    TechnicalReport Monograph Adjunct WorkInProgress
  ].freeze

  FIXTURE_LINES = Dir
    .glob(File.join(__dir__, "../../fixtures/astm/**/*.txt"))
    .reject { |f| f.include?("/fail/") }
    .flat_map { |f| File.readlines(f, chomp: true) }
    .map(&:strip).reject(&:empty?).reject { |l| l.start_with?("#") }
    .uniq.freeze

  def self.parsed_corpus
    @parsed_corpus ||= FIXTURE_LINES.filter_map do |line|
      id = begin
        Pubid::Astm.parse(line)
      rescue StandardError, Parslet::ParseFailed
        nil
      end
      [line, id] if id
    end
  end
end

RSpec.describe "Pubid::Astm index key (root.number)" do
  describe "structural tripwire (full-suite only)" do
    AstmIndexKeySpec::CONCRETE.each do |leaf|
      it "declares `number` as a String on #{leaf}" do
        klass = Pubid::Astm::Identifiers.const_get(leaf)
        expect(klass.attributes[:number].type)
          .to eq(Lutaml::Model::Type::String)
      end
    end

    it "leaves the inherited-from classes' `number` untouched" do
      [Pubid::Astm::Identifier, Pubid::Astm::SingleIdentifier,
       Pubid::Astm::Identifiers::Base].each do |klass|
        expect(klass.attributes[:number].type).to eq(Pubid::Components::Code)
      end
    end

    it "no longer declares a `code` attribute" do
      expect(Pubid::Astm::SingleIdentifier.attributes).not_to have_key(:code)
      expect(Pubid::Astm::Identifiers::Standard.attributes)
        .not_to have_key(:code)
    end
  end

  describe "per-type index key" do
    AstmIndexKeySpec::KEYS.each do |ref, (klass, key)|
      context ref do
        subject(:id) { Pubid::Astm.parse(ref) }

        it "is a #{klass}" do
          expect(id.class.name.split("::").last).to eq(klass)
        end

        it "keys on #{key.inspect}" do
          expect(id.root.number.to_s).to eq(key)
        end
      end
    end

    it "keeps the letter in its own column, out of the key" do
      id = Pubid::Astm.parse("ASTM E2938-15(2023)")
      expect(id.letter).to eq("E")
      expect(id.number).to eq("2938")
      expect(id.code.to_s).to eq("E2938")
    end
  end

  describe "the whole fixture corpus" do
    it "parses a corpus worth sweeping" do
      expect(AstmIndexKeySpec.parsed_corpus.size).to be >= 248
    end

    it "gives every identifier a non-empty root.number" do
      bad = AstmIndexKeySpec.parsed_corpus.select do |_, id|
        id.root.number.to_s.empty?
      end
      expect(bad.map(&:first).first(5)).to eq([])
    end

    it "round-trips every identifier through from_hash(to_hash)" do
      bad = AstmIndexKeySpec.parsed_corpus.select do |_, id|
        h = id.to_hash
        Pubid::Astm::Identifier.from_hash(h).to_hash != h
      end
      expect(bad.map(&:first).first(5)).to eq([])
    end

    # to_slug is an output FILENAME. Before this change 201 of the 248 ids
    # shared the slug "astm" and 40 more RAISED NoMethodError, because
    # `mr_edition` calls `edition.number` on ASTM's plain-String edition — the
    # same crash BIPM had.
    it "never raises and stays filename-safe" do
      slugs = AstmIndexKeySpec.parsed_corpus.map do |_, id|
        expect { id.to_mr_string }.not_to raise_error
        id.to_mr_string
      end
      expect(slugs.count(&:empty?)).to eq(0)
      expect(slugs.grep(/[^a-z0-9._-]/).first(5)).to eq([])
    end

    it "gives distinct identifiers distinct slugs" do
      by_slug = AstmIndexKeySpec.parsed_corpus
        .group_by { |_, id| id.to_mr_string }
      clashing = by_slug.reject do |_, rows|
        rows.map { |_, id| id.to_hash }.uniq.size == 1
      end
      expect(clashing.keys.first(5)).to eq([])
    end
  end

  # Renderers::MrString joins segments with "." and `compact` drops nil but NOT
  # "", so a hook returning an empty string would contribute a blank segment and
  # a double dot. Every override that appends its own marker to `super` routes
  # through Pubid::Identifier#mr_join, which returns nil when nothing survives.
  describe "an empty number segment never reaches the slug" do
    it "returns nil, not an empty string" do
      expect(Pubid::Astm::Identifiers::Standard.new.mr_number_with_part)
        .to be_nil
    end

    it "produces no double dot" do
      expect(Pubid::Astm::Identifiers::Standard.new.to_mr_string)
        .not_to include("..")
    end
  end

  # Giving the adjunct a number also repaired its URN: all four adjuncts in the
  # corpus used to emit the bare, identity-free "urn:astm:std".
  describe "adjunct URNs carry the designation" do
    {
      "ASTM ADJD2148" => "urn:astm:std:D2148",
      "ASTM ADJF3504-EA" => "urn:astm:std:F3504",
      "ASTM ADJG0088DVD" => "urn:astm:std:G0088",
      "ASTM ADJC062702" => "urn:astm:std:C062702",
    }.each do |ref, urn|
      it "#{ref} -> #{urn}" do
        expect(Pubid::Astm.parse(ref).to_urn.to_s).to eq(urn)
      end
    end
  end

  # Every marker that distinguishes two real documents has to reach the slug,
  # not just `==` and the hash — CLAUDE.md's cross-cutting rule.
  describe "identity markers reach the slug" do
    {
      "reapproval" => ["ASTM C1870-18(2024)", "ASTM C1870-18"],
      "tp_designation" => ["ASTM MNLTP15-EB", "ASTM MNL15-EB"],
      "manual supplement" => ["ASTM MNL20-2ND-SUP-EB", "ASTM MNL20-2ND-EB"],
      "research-report committee" => ["ASTM RR:A01-1001", "ASTM RR:C09-1001"],
    }.each do |marker, (a, b)|
      it "distinguishes on #{marker}" do
        expect(Pubid::Astm.parse(a).to_mr_string)
          .not_to eq(Pubid::Astm.parse(b).to_mr_string)
      end
    end
  end
end
