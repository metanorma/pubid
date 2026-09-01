# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for OIML, plus the structural tripwire for the
# `number` attribute.
#
# Relaton::Index::Type#candidates_by_number sorts and bsearches every index row
# on `id.root.number.to_s`. OIML kept the document code in an
# Oiml::Components::Code under its own `code` attribute and never set the
# `number` it inherits from ::Pubid::Identifier, so every row of the published
# relaton-data-oiml index-v2 shared the empty key "" and the binary search
# degraded to a linear scan — silently, with no error.
#
# The serialized hash was ALREADY flat (`number`, `part`, `subpart`, `suffix`,
# `space_suffix` as bare top-level scalars, emitted by converters reading
# through `code`), so this is a runtime model change only: the wire format does
# not move and the published index needs no regeneration. Asserted below.
#
# This file also carries OIML's fixture sweep, which is load-bearing:
# spec/pubid/oiml/fixtures_spec.rb globs "../../../fixtures/OIML/..." — one
# ".." too many AND an uppercase directory — so it reports 0 examples and has
# never checked anything. See the hand-off
# HANDOFFS/metanorma__pubid__ten-dead-fixture-specs.md.
#
# IMPORTANT: the structural block is only meaningful under the FULL suite
# (`bundle exec rake`), never `rspec spec/pubid/oiml` alone.
# Oiml::Components::Code is NOT a subclass of Pubid::Components::Code, so
# naming the attribute `number` retypes the inherited one — the multi-flavor
# determinism landmine recorded in CLAUDE.md for IEEE/IETF/IANA/CIE. It is
# therefore declared on each concrete LEAF by Identifiers::CodeNumber, never on
# the shared SingleIdentifier that all seven inherit.
module OimlIndexKeySpec
  # printed reference => [leaf class, index key]
  KEYS = {
    "OIML R 106" => ["Recommendation", "106"],
    # the part is a sibling column, so all parts of a document share a bucket
    "OIML R 49-3:2013(E)" => ["Recommendation", "49"],
    "OIML R 144-1 Edition 2013 (E)" => ["Recommendation", "144"],
    "OIML D 11:2008" => ["Document", "11"],
    "OIML V 2:2013(E/F)" => ["Vocabulary", "2"],
    "OIML G 1-100:2008" => ["Guide", "1"],
    "OIML B 18:2018" => ["BasicPublication", "18"],
    "OIML E 5:2015(en)" => ["ExpertReport", "5"],
    "OIML S 6:2011(en)" => ["SeminarReport", "6"],
    # supplements carry no number of their own; the key comes from the base
    # standard through #root
    "Amendment (2009) to OIML R 138 Edition 2007 (E)" => ["Amendment", "138"],
    "OIML R 60 Annex A Edition 2013 (E)" => ["Annex", "60"],
  }.freeze

  # The seven code-bearing leaves. Bulletin is deliberately absent: it has no
  # code and derives its key from the year.
  CODE_LEAVES = %w[
    Recommendation Document Vocabulary Guide
    BasicPublication ExpertReport SeminarReport
  ].freeze

  FIXTURE_LINES = Dir
    .glob(File.join(__dir__, "../../fixtures/oiml/**/*.txt"))
    .reject { |f| f.include?("/fail/") }
    .flat_map { |f| File.readlines(f, chomp: true) }
    .map(&:strip).reject(&:empty?).reject { |l| l.start_with?("#") }
    .uniq.freeze

  def self.parsed_corpus
    @parsed_corpus ||= FIXTURE_LINES.filter_map do |line|
      id = begin
        Pubid::Oiml.parse(line)
      rescue StandardError, Parslet::ParseFailed
        nil
      end
      [line, id] if id
    end
  end
end

RSpec.describe "Pubid::Oiml index key (root.number)" do
  describe "structural tripwire (full-suite only)" do
    OimlIndexKeySpec::CODE_LEAVES.each do |leaf|
      it "declares `number` as a String on the #{leaf} LEAF" do
        klass = Pubid::Oiml::Identifiers.const_get(leaf)
        expect(klass.attributes[:number].type)
          .to eq(Lutaml::Model::Type::String)
      end
    end

    it "leaves SingleIdentifier's inherited `number` untouched" do
      # A redeclaration here is the determinism landmine: all seven leaves
      # inherit from this class.
      expect(Pubid::Oiml::SingleIdentifier.attributes[:number].type)
        .to eq(Pubid::Components::Code)
    end

    it "no longer declares a `code` attribute" do
      expect(Pubid::Oiml::SingleIdentifier.attributes).not_to have_key(:code)
      expect(Pubid::Oiml::Identifiers::Recommendation.attributes)
        .not_to have_key(:code)
    end

    it "does not give Bulletin the code columns" do
      expect(Pubid::Oiml::Identifiers::Bulletin.attributes)
        .not_to have_key(:suffix)
    end
  end

  describe "per-type index key" do
    OimlIndexKeySpec::KEYS.each do |ref, (klass, key)|
      context ref do
        subject(:id) { Pubid::Oiml.parse(ref) }

        it "is a #{klass}" do
          expect(id.class.name.split("::").last).to eq(klass)
        end

        it "keys on #{key.inspect}" do
          expect(id.root.number.to_s).to eq(key)
        end
      end
    end
  end

  # Bulletin has no code; its key is the year, clustering a volume's issues and
  # articles into one bucket (the BIPM Metrologia-volume precedent).
  describe "Bulletin derives its key from the year" do
    {
      "OIML Bulletin 1960-03-01" => "1960",
      "OIML Bulletin 1960-03" => "1960",
      "OIML Bulletin 1960" => "1960",
    }.each do |ref, key|
      it "#{ref} keys on #{key.inspect}" do
        expect(Pubid::Oiml.parse(ref).root.number.to_s).to eq(key)
      end
    end

    it "adds no `number` key to the serialized hash" do
      # A derived reader, not an attribute: storing it would duplicate `year`.
      expect(Pubid::Oiml.parse("OIML Bulletin 1960-03-01").to_hash)
        .not_to have_key("number")
    end

    # Deliberate gap, pinned so it stays visible: the bare periodical
    # reference names no year, so it has no key. Same shape as BIPM's
    # ordinal-less CGPM DECL.
    it "leaves the bare periodical reference without a key" do
      expect(Pubid::Oiml.parse("OIML Bulletin").root.number).to be_nil
    end

    # The coarse volume key is only defensible while the MR slug — which
    # consumers use as an output FILENAME — stays per-article.
    it "keeps every article of a volume distinct in the MR slug" do
      slugs = [
        "OIML Bulletin 1960",
        "OIML Bulletin 1960-03",
        "OIML Bulletin 1960-03-01",
        "OIML Bulletin 1960-03-02",
        "OIML Bulletin 1961-03-01",
      ].map { |r| Pubid::Oiml.parse(r).to_mr_string }
      expect(slugs.uniq.size).to eq(slugs.size)
      expect(slugs).to include("oiml.bulletin.03-01.1960")
    end

    it "does not repeat the year inside the number segment" do
      expect(Pubid::Oiml.parse("OIML Bulletin 1960-03-01").to_mr_string)
        .to eq("oiml.bulletin.03-01.1960")
    end
  end

  # A supplement descends from Oiml::Identifier directly — it is a SIBLING of
  # SingleIdentifier, where `code` and `iteration` live — so UrnGenerator,
  # which reads both unconditionally, raised NoMethodError for every
  # Amendment, Errata and Annex. Verified against a baseline captured on main:
  # all five supplement fixtures already raised there. They now delegate to
  # `base`.
  describe "supplement URNs (pre-existing crash, fixed here)" do
    [
      "Amendment (2009) to OIML R 138 Edition 2007 (E)",
      "Amendment (2009) to OIML R 138:2007 (E)",
      "OIML R 60 Annex A Edition 2013 (E)",
      "OIML R 60 Annexes Edition 2021 (E)",
      "OIML R 60 Annexes:2021 (E)",
    ].each do |ref|
      it "#{ref} generates a URN instead of raising" do
        expect { Pubid::Oiml.parse(ref).to_urn }.not_to raise_error
        expect(Pubid::Oiml.parse(ref).to_urn.to_s).to start_with("urn:oiml:")
      end
    end

    # KNOWN GAP, pre-existing and deliberately not closed here: the OIML URN
    # shape encodes no supplement marker, so an annex, an amendment and the
    # standard they attach to all share one URN. Same shape as the documented
    # ITU supplement-URN gap. Closing it needs a URN-shape decision, not a
    # delegation. Pinned so it stays visible.
    it "does not yet distinguish a supplement from its base in the URN" do
      annex = Pubid::Oiml.parse("OIML R 60 Annex A Edition 2013 (E)")
        .to_urn.to_s
      base = Pubid::Oiml.parse("OIML R 60:2013(E)").to_urn.to_s
      expect(annex).to eq(base)
    end

    # KNOWN GAP, pre-existing: a supplement inherits none of SingleIdentifier's
    # mr_* hooks, so its slug is empty and every OIML supplement collides on
    # what consumers use as a filename. Unchanged by this branch (baseline on
    # main was also ""). See hand-off oiml-supplement-identity-surfaces.
    it "still has an empty MR slug" do
      expect(Pubid::Oiml.parse("OIML R 60 Annex A Edition 2013 (E)")
        .to_mr_string).to eq("")
    end
  end

  describe "the whole fixture corpus" do
    it "parses a corpus worth sweeping" do
      expect(OimlIndexKeySpec.parsed_corpus.size).to be >= 57
    end

    it "gives every identifier a non-empty root.number" do
      bad = OimlIndexKeySpec.parsed_corpus.select do |_, id|
        id.root.number.to_s.empty?
      end
      expect(bad.map(&:first)).to eq([])
    end

    it "round-trips every identifier through from_hash(to_hash)" do
      bad = OimlIndexKeySpec.parsed_corpus.reject do |_, id|
        h = id.to_hash
        Pubid::Oiml::Identifier.from_hash(h).to_hash == h
      end
      expect(bad.map(&:first)).to eq([])
    end
  end

  # The point of the change: the wire format does not move, so the published
  # relaton-data-oiml index-v2 does not need regenerating.
  describe "serialized shape is unchanged" do
    it "keeps the flat scalar keys, including the suffix pair" do
      expect(Pubid::Oiml.parse("OIML G 1-100:2008").to_hash)
        .to eq(
          "_type" => "pubid:oiml:guide",
          "publisher" => "OIML",
          "number" => "1",
          "part" => "100",
          "year" => "2008",
        )
    end

    it "omits space_suffix when false" do
      expect(Pubid::Oiml.parse("OIML R 106").to_hash)
        .not_to have_key("space_suffix")
    end
  end
end
