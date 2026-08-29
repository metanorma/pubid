# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for CSA, plus the structural tripwire for the
# `number` attribute.
#
# Relaton::Index::Type#candidates_by_number sorts and bsearches every index row
# on `id.root.number.to_s`. CSA used to keep the document code in its own
# `code` attribute and never set the inherited `number`, and five of its eight
# types were not Pubid::Identifier objects at all — so `root.number` returned
# nil for 229 fixture ids and *raised* NoMethodError for 600 more. CSA was the
# only flavor in the gem where the index key raised: a raise aborts a crawl,
# where an empty key merely degrades a search.
#
# IMPORTANT: the structural block below is only meaningful under the FULL suite
# (`bundle exec rake`), never `rspec spec/pubid/csa` alone. CSA declares no
# `number` override of its own — Pubid::Csa::Components::Code IS
# Pubid::Components::Code, so the code and the inherited
# `attribute :number, Components::Code` are the same type and the attribute is
# simply used rather than redeclared. That is what keeps CSA clear of the
# multi-flavor determinism landmine recorded in CLAUDE.md for IEEE/IETF/IANA,
# which would otherwise apply: CSA's base IS split across two files
# (csa/identifier.rb + csa/single_identifier.rb), the shape in which a leaf can
# snapshot a half-built parent attribute table. These assertions fail
# immediately if someone reintroduces a redeclaration.
module CsaIndexKeySpec
  # One entry per identifier type: printed reference => [leaf class, key].
  KEYS = {
    "CSA B149.1:F20" => ["Standard", "B149.1"],
    "CSA C22.2 NO. 286:23" => ["Cec", "C22.2-286"],
    "CSA Z240 MH SERIES:16 (R2025)" => ["Series", "Z240"],
    "CAN/CSA-A123.2-03 (R2023)" => ["CanadianAdopted", "A123.2"],
    "CSA ISO/IEC 8824-1:22" => ["CsaAdopted", "8824"],
    "CSA B149.1:25 Code, Handbook & Training Package" =>
      ["Package", "B149.1"],
    "CSA A23.1:24/CSA A23.2:24" => ["Combined", "A23.1"],
    "CSA B44:19/B44.1:19/B44.2:19" => ["Combined", "B44"],
    "CAN/CSA-C22.2 NO. 60601-1-6:11 + A1:15 + A2:21 (R2021) (CONSOLIDATED)" =>
      ["Bundled", "C22.2-60601-1-6"],
  }.freeze

  # Every concrete type. The three single-document leaves carry the key
  # themselves; the five containers reach it through `base`/`identifiers`.
  LEAVES = %w[
    Standard Cec Series
    CanadianAdopted CsaAdopted Package Combined Bundled
  ].freeze

  SINGLE_LEAVES = %w[Base Standard Cec Series].freeze

  # Every fixture line outside fail/, deduplicated. The acceptance sweep.
  FIXTURE_LINES = Dir
    .glob(File.join(__dir__, "../../fixtures/csa/**/*.txt"))
    .reject { |f| f.include?("/fail/") }
    .flat_map { |f| File.readlines(f, chomp: true) }
    .map(&:strip).reject(&:empty?).uniq.freeze

  # Parsed once and shared: the sweep blocks below all read the same corpus.
  def self.parsed_corpus
    @parsed_corpus ||= FIXTURE_LINES.filter_map do |line|
      [line, Pubid::Csa::Identifier.parse(line)]
    rescue Parslet::ParseFailed, ArgumentError
      nil
    end
  end
end

RSpec.describe "Pubid::Csa index key (root.number)" do
  def parse(str)
    Pubid::Csa::Identifier.parse(str)
  end

  def parsed_corpus
    CsaIndexKeySpec.parsed_corpus
  end

  # The structural half. The examples further down prove the *effect*, but
  # would still pass if a leaf had snapshotted a differently-typed `number`;
  # these read the attribute definitions directly.
  describe "number resolves to Components::Code everywhere" do
    it "is Components::Code on the shared base" do
      expect(Pubid::Csa::Identifier.attributes[:number].type)
        .to eq(Pubid::Components::Code)
    end

    it "is Components::Code on SingleIdentifier" do
      expect(Pubid::Csa::SingleIdentifier.attributes[:number].type)
        .to eq(Pubid::Components::Code)
    end

    CsaIndexKeySpec::SINGLE_LEAVES.each do |leaf|
      it "reaches Identifiers::#{leaf} as Components::Code" do
        klass = Pubid::Csa::Identifiers.const_get(leaf)
        expect(klass.attributes[:number].type)
          .to eq(Pubid::Components::Code)
      end
    end

    it "no longer declares the historical `code` attribute" do
      expect(Pubid::Csa::SingleIdentifier.attributes).not_to have_key(:code)
    end

    it "no longer exposes `code` on a parsed identifier" do
      expect(parse("CSA B149.1:F20")).not_to respond_to(:code)
    end
  end

  # Every container is a real Pubid::Identifier, so it inherits #root,
  # #exclude, the polymorphic from_hash and the MR renderer.
  describe "every type is a Pubid::Identifier" do
    CsaIndexKeySpec::LEAVES.each do |leaf|
      it "Identifiers::#{leaf} descends from Pubid::Csa::Identifier" do
        klass = Pubid::Csa::Identifiers.const_get(leaf)
        expect(klass).to be < Pubid::Csa::Identifier
      end
    end

    it "the wrapper base class is a Pubid::Identifier" do
      expect(Pubid::Csa::WrapperIdentifier).to be < Pubid::Csa::Identifier
    end

    it "the composite base class is a Pubid::Identifier" do
      expect(Pubid::Csa::CompositeIdentifier).to be < Pubid::Csa::Identifier
    end
  end

  # The uniform parent accessor CLAUDE.md mandates. There is no
  # `base` alias.
  describe "uniform `base` accessor" do
    it "a Canadian adoption exposes its wrapped standard under #base" do
      id = parse("CAN/CSA-A123.2-03 (R2023)")
      expect(id.base).to be_a(Pubid::Csa::Identifiers::Standard)
    end

    it "a CSA adoption exposes a cross-flavor wrapped id under #base" do
      id = parse("CSA ISO/IEC 8824-1:22")
      expect(id.base).to be_a(Pubid::Iso::Identifier)
    end

    it "does not keep a `wrapped_identifier` alias" do
      expect(parse("CAN/CSA-A123.2-03 (R2023)"))
        .not_to respond_to(:wrapped_identifier)
    end

    it "a plain standard has a nil #base" do
      expect(parse("CSA B149.1:F20").base).to be_nil
    end
  end

  describe "root.number is the index key" do
    CsaIndexKeySpec::KEYS.each do |ref, (leaf, key)|
      context ref do
        let(:parsed) { parse(ref) }

        it "builds Identifiers::#{leaf}" do
          expect(parsed).to be_a(Pubid::Csa::Identifiers.const_get(leaf))
        end

        it "keys on #{key.inspect}" do
          expect(parsed.root.number.to_s).to eq(key)
        end

        it "keys non-empty for Relaton::Index" do
          expect(parsed.root.number.to_s).not_to be_empty
        end

        it "survives a from_hash round-trip with the key intact" do
          rebuilt = Pubid::Csa::Identifier.from_hash(parsed.to_hash)
          expect(rebuilt.root.number.to_s).to eq(key)
          expect(rebuilt.to_s).to eq(parsed.to_s)
        end
      end
    end

    it "a container roots to the document it wraps, not to itself" do
      id = parse("CAN/CSA-A123.2-03 (R2023)")
      expect(id.root).not_to equal(id)
      expect(id.root).to be_a(Pubid::Csa::Identifiers::Standard)
    end

    it "a single document is its own root" do
      id = parse("CSA B149.1:F20")
      expect(id.root).to equal(id)
    end
  end

  # `Combined` holds co-equal designations in one collection rather than the
  # historical first/second/third triple, so a joint reference of any arity
  # parses and keys on its primary designation.
  describe "Combined holds an identifiers collection" do
    it "keeps two designations" do
      expect(parse("CSA A23.1:24/CSA A23.2:24").identifiers.size).to eq(2)
    end

    it "keeps three designations" do
      expect(parse("CSA B44:19/B44.1:19/B44.2:19").identifiers.size).to eq(3)
    end

    it "no longer exposes the historical triple" do
      expect(parse("CSA A23.1:24/CSA A23.2:24")).not_to respond_to(:first)
    end
  end

  # `parse` returns an identifier or raises — never nil. Every other flavor
  # except `api` already honours this; a nil silently becomes a NoMethodError
  # in the caller instead of a catchable parse failure.
  describe "#parse never returns nil" do
    {
      "a comment line" => "# a comment",
      "a non-standard product" => "CSA Communities Membership",
      "an unparseable string" => "ZZZ nonsense 999",
      "a generator artifact" => "!CAN/CSA-ISO 10993.11-98 (R2003)!",
    }.each do |what, input|
      it "raises Parslet::ParseFailed for #{what}" do
        expect { Pubid::Csa::Identifier.parse(input) }
          .to raise_error(Parslet::ParseFailed)
      end
    end

    it "never returns nil across the whole fixture corpus" do
      nils = CsaIndexKeySpec::FIXTURE_LINES.select do |line|
        Pubid::Csa::Identifier.parse(line).nil?
      rescue Parslet::ParseFailed, ArgumentError
        false
      end

      expect(nils).to be_empty
    end
  end

  # `exclude` reaches the wrapped identifier now that `base` is a real
  # attribute rather than an attr_accessor invisible to the attribute loop.
  describe "#exclude reaches a wrapped identifier" do
    it "clears the year inside a Canadian adoption" do
      id = parse("CAN/CSA-A123.2-03 (R2023)")
      expect(id.base.year).not_to be_nil
      expect(id.exclude(:year).base.year).to be_nil
    end

    it "makes a year-less reference match every edition" do
      bare = parse("CAN/CSA-A123.2")
      dated = parse("CAN/CSA-A123.2-03")
      expect(bare.matches?(dated, ignore: [:year])).to be true
    end
  end

  # The serialized shape is FLAT: the Components::Code attributes collapse to
  # bare scalars via the key_value block on SingleIdentifier, so a row reads
  # `number: B149.1` rather than `number: {value: B149.1}`. The runtime
  # attribute is still a Components::Code — this is a serialization mapping,
  # not the `attribute :number, :string` retype that CSA's split base makes
  # unsafe.
  describe "serialized shape" do
    it "emits a scalar number for a plain standard" do
      expect(parse("CSA B149.1:F20").to_hash).to eq(
        "_type" => "pubid:csa:standard",
        "number" => "B149.1",
        "year" => "2020",
        "year_format" => "colon",
        "year_prefix" => "F",
        "french" => true,
        "has_publisher" => true,
        "publisher_prefix" => "CSA",
      )
    end

    it "emits all three code halves flat for a CEC identifier" do
      expect(parse("CSA C22.2 NO. 286:23").to_hash).to eq(
        "_type" => "pubid:csa:cec",
        "number" => "C22.2-286",
        "no_number" => "286",
        "cec_part" => "C22.2",
        "year" => "2023",
        "year_format" => "colon",
        "publisher_prefix" => "CSA",
      )
    end

    it "flattens a nested base inside a container too" do
      expect(parse("CAN/CSA-A123.2-03 (R2023)").to_hash["base"])
        .to include("number" => "A123.2")
    end

    it "drops a default-valued flag from the canonical hash" do
      hash = parse("CSA B149.1:F20").to_hash
      expect(hash).not_to have_key("code_only")
      expect(hash).not_to have_key("original_year_4digit")
    end

    it "keeps the flag when it is the rare, non-default value" do
      expect(parse("C22.1-15").to_hash).to include("code_only" => true)
    end

    it "still exposes number as a Components::Code at runtime" do
      expect(parse("CSA B149.1:F20").number)
        .to be_a(Pubid::Components::Code)
    end
  end

  # The matching vocabulary relaton uses to normalise a reference before
  # comparing it. These are inherited now that the containers are real
  # identifiers, so each one must peel to the document it wraps — the
  # inherited default returns the wrapper, a silently wrong answer.
  describe "matching primitives peel to the wrapped document" do
    {
      "CAN/CSA-A123.2-03 (R2023)" => "Pubid::Csa::Identifiers::Standard",
      "CSA ISO/IEC 8824-1:22" => "Pubid::Iso::Identifiers::InternationalStandard",
      "CSA A23.1:24/CSA A23.2:24" => "Pubid::Csa::Identifiers::Standard",
      "CSA B149.1:25 Code, Handbook & Training Package" =>
        "Pubid::Csa::Identifiers::Standard",
      "CAN/CSA-C22.2 NO. 60601-1-6:11 + A1:15 + A2:21 (R2021) (CONSOLIDATED)" =>
        "Pubid::Csa::Identifiers::Cec",
    }.each do |ref, klass|
      context ref do
        let(:parsed) { parse(ref) }

        it "#base_document reaches #{klass.split('::').last}" do
          expect(parsed.base_document).to be_a(Object.const_get(klass))
        end

        it "#drop_supplements reaches #{klass.split('::').last}" do
          expect(parsed.drop_supplements).to be_a(Object.const_get(klass))
        end
      end
    end

    it "leaves a single document as its own base_document" do
      id = parse("CSA B149.1:F20")
      expect(id.base_document).to equal(id)
    end
  end

  # KNOWN GAP, pre-existing and deliberately not closed here: CSA defines no
  # URN shape for a container. `UrnGenerator` reads `publisher_prefix`/`number`
  # straight off the identifier, which a container does not carry, so `to_urn`
  # raises. This is byte-for-byte the behaviour on `main` — the containers
  # raised the same NoMethodError from the same place before they became
  # identifiers — so nothing regressed; but closing it needs a URN-shape
  # decision per container type (a bare delegation would collide an adoption
  # with the standard it adopts). Pinned so the gap stays visible.
  describe "container URNs (known gap)" do
    [
      "CAN/CSA-A123.2-03 (R2023)",
      "CSA ISO/IEC 8824-1:22",
      "CSA A23.1:24/CSA A23.2:24",
      "CSA B149.1:25 Code, Handbook & Training Package",
    ].each do |ref|
      it "#{ref} has no URN shape yet" do
        expect { parse(ref).to_urn }.to raise_error(NoMethodError)
      end
    end

    it "a single document still has a URN" do
      expect(parse("CSA B149.1:F20").to_urn.to_s).to start_with("urn:csa:")
    end
  end

  describe "the whole fixture corpus" do
    it "yields a non-empty root.number for every parsing line" do
      bad = parsed_corpus.filter_map do |line, id|
        key = begin
          id.root.number.to_s
        rescue StandardError => e
          "raised #{e.class}"
        end
        [line, key] if key.empty? || key.start_with?("raised ")
      end

      expect(bad).to be_empty
    end

    it "round-trips through from_hash for every parsing line" do
      bad = parsed_corpus.filter_map do |line, id|
        hash = id.to_hash
        rebuilt = Pubid::Csa::Identifier.from_hash(hash)
        line unless rebuilt.to_hash == hash && rebuilt.to_s == id.to_s
      rescue StandardError => e
        "#{line} (#{e.class})"
      end

      expect(bad).to be_empty
    end
  end

  # `to_slug` is an output filename, so the MR string is sanitised by CHARSET
  # rather than by an enumerated escape list — a character introduced later
  # cannot leak through. The BIPM mr_slug precedent.
  describe "MR string" do
    it "is filename-safe for every parsing line" do
      unsafe = parsed_corpus.filter_map do |line, id|
        slug = id.to_mr_string
        "#{line} -> #{slug}" unless slug.match?(/\A[a-z0-9._-]+\z/)
      rescue StandardError => e
        "#{line} (#{e.class})"
      end

      expect(unsafe).to be_empty
    end

    it "does not collide across the corpus" do
      slugs = parsed_corpus.map { |_, id| id.to_mr_string }
      dupes = slugs.tally.select { |_, n| n > 1 }
      expect(dupes).to be_empty
    end

    it "neutralises parentheses in a reaffirmation" do
      expect(parse("CSA C22.2 NO. 100:14 (R2024)").to_mr_string)
        .to match(/\A[a-z0-9._-]+\z/)
    end

    it "is defined for a bundled identifier" do
      id = parse(
        "CAN/CSA-C22.2 NO. 60601-1-6:11 + A1:15 + A2:21 (R2021) (CONSOLIDATED)",
      )
      expect(id.to_mr_string).to match(/\A[a-z0-9._-]+\z/)
    end
  end
end
