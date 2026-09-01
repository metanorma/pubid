# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for ETSI, plus the structural tripwire for the
# `number` attribute.
#
# Relaton::Index::Type#candidates_by_number sorts and bsearches every index row
# on `id.root.number.to_s`. ETSI kept the document code in an
# `Etsi::Components::Code` object under its own `code` attribute and never set
# the `number` it inherits from ::Pubid::Identifier, so all 24,724 parseable
# fixture ids — and every row of the published relaton-data-etsi index-v2 —
# shared the empty key "" and the binary search degraded to a linear scan,
# silently and with no error.
#
# The serialized hash was ALREADY flat (`number`, `parts`, `minor` as bare
# scalars, emitted by converters reading through `code`), so this is a runtime
# model change only: the wire format does not move and the published index
# needs no regeneration. That equivalence is asserted below.
#
# IMPORTANT: the structural block is only meaningful under the FULL suite
# (`bundle exec rake`), never `rspec spec/pubid/etsi` alone. Etsi::Components::Code
# is NOT a subclass of Pubid::Components::Code, so naming the attribute `number`
# retypes the inherited one — the multi-flavor determinism landmine recorded in
# CLAUDE.md for IEEE/IETF/IANA/CIE. It is therefore declared on the LEAF
# (EtsiStandard, which nothing subclasses) and never on the shared
# Pubid::Etsi::Identifier that SupplementIdentifier also inherits.
module EtsiIndexKeySpec
  # printed reference => [leaf class, index key]
  KEYS = {
    # plain standard, no part
    "ETSI EG 200 053 V1.5.1 (2004-06)" => ["EtsiStandard", "200 053"],
    # parted standard: the key is the BARE number, so every part of a
    # document shares one bucket and a part-less reference finds them all
    "ETSI EG 201 026-1 V1.1.1 (1997-07)" => ["EtsiStandard", "201 026"],
    "ETSI EN 300 175-1 V2.6.1 (2015-07)" => ["EtsiStandard", "300 175"],
    # edition form (is_edition) rather than a version
    "ETSI ETR 001 ed.1 (1990-08)" => ["EtsiStandard", "001"],
    # letter-series numbers keep their series token in the number
    "ETSI GR ARF 001 V1.1.1 (2019-04)" => ["EtsiStandard", "ARF 001"],
    "ETSI GS ZSM 012" => ["EtsiStandard", "ZSM 012"],
    # GSM dotted form
    "ETSI GTS GSM 02.01 V5.5.0 (1999-01)" => ["EtsiStandard", "GSM 02.01"],
    # supplements carry their own ordinal in `number`; the index key comes
    # from the base standard through #root
    "ETSI ETR 053/C1 ed.2 (1997-03)" => ["Corrigendum", "053"],
    "ETSI ETR 108/A1 ed.1 (1995-08)" => ["Amendment", "108"],
  }.freeze

  # Every fixture line outside fail/, deduplicated. The acceptance sweep.
  FIXTURE_LINES = Dir
    .glob(File.join(__dir__, "../../fixtures/etsi/**/*.txt"))
    .reject { |f| f.include?("/fail/") }
    .flat_map { |f| File.readlines(f, chomp: true) }
    .map(&:strip).reject(&:empty?).reject { |l| l.start_with?("#") }
    .uniq.freeze

  def self.parsed_corpus
    @parsed_corpus ||= FIXTURE_LINES.filter_map do |line|
      id = begin
        Pubid::Etsi.parse(line)
      rescue StandardError, Parslet::ParseFailed
        nil
      end
      [line, id] if id
    end
  end
end

RSpec.describe "Pubid::Etsi index key (root.number)" do
  describe "structural tripwire (full-suite only)" do
    it "declares `number` as a String on the EtsiStandard LEAF" do
      expect(Pubid::Etsi::Identifiers::EtsiStandard.attributes[:number].type)
        .to eq(Lutaml::Model::Type::String)
    end

    it "leaves the shared base's inherited `number` untouched" do
      # A redeclaration here is the determinism landmine: EtsiStandard and
      # SupplementIdentifier both inherit from this class.
      expect(Pubid::Etsi::Identifier.attributes[:number].type)
        .to eq(Pubid::Components::Code)
    end

    it "no longer declares a `code` attribute anywhere in the hierarchy" do
      expect(Pubid::Etsi::Identifier.attributes).not_to have_key(:code)
      expect(Pubid::Etsi::Identifiers::EtsiStandard.attributes)
        .not_to have_key(:code)
    end

    it "splits the remaining Code fields into sibling attributes" do
      attrs = Pubid::Etsi::Identifiers::EtsiStandard.attributes
      expect(attrs[:minor].type).to eq(Lutaml::Model::Type::String)
      expect(attrs[:parts].type).to eq(Lutaml::Model::Type::String)
      expect(attrs[:parts]).to be_collection
    end
  end

  describe "per-type index key" do
    EtsiIndexKeySpec::KEYS.each do |ref, (klass, key)|
      context ref do
        subject(:id) { Pubid::Etsi.parse(ref) }

        it "is a #{klass}" do
          expect(id.class.name.split("::").last).to eq(klass)
        end

        it "keys on #{key.inspect}" do
          expect(id.root.number.to_s).to eq(key)
        end
      end
    end
  end

  describe "the whole fixture corpus" do
    it "parses a corpus worth sweeping" do
      expect(EtsiIndexKeySpec.parsed_corpus.size).to be > 24_000
    end

    it "gives every identifier a non-empty root.number" do
      bad = EtsiIndexKeySpec.parsed_corpus.select do |_, id|
        id.root.number.to_s.empty?
      end
      expect(bad.map(&:first).first(10)).to eq([])
    end

    it "round-trips every identifier through from_hash(to_hash)" do
      bad = EtsiIndexKeySpec.parsed_corpus.reject do |_, id|
        h = id.to_hash
        Pubid::Etsi::Identifier.from_hash(h).to_hash == h
      end
      expect(bad.map(&:first).first(10)).to eq([])
    end
  end

  # The point of the change: the wire format does not move, so the published
  # relaton-data-etsi index-v2 does not need regenerating.
  describe "serialized shape is unchanged" do
    it "keeps the flat scalar keys for a plain standard" do
      expect(Pubid::Etsi.parse("ETSI EG 200 053 V1.5.1 (2004-06)").to_hash)
        .to eq(
          "_type" => "pubid:etsi:etsi-standard",
          "type" => "EG",
          "number" => "200 053",
          "version" => "1.5.1",
          "year" => "2004",
          "month" => "06",
        )
    end

    it "keeps `parts` as a bare array, omitted when empty" do
      parted = Pubid::Etsi.parse("ETSI EG 201 026-1 V1.1.1 (1997-07)").to_hash
      expect(parted["parts"]).to eq(["1"])
      expect(Pubid::Etsi.parse("ETSI GS ZSM 012").to_hash)
        .not_to have_key("parts")
    end

    it "keeps the supplement's own ordinal and nested base" do
      expect(Pubid::Etsi.parse("ETSI ETR 053/C1 ed.2 (1997-03)").to_hash)
        .to eq(
          "_type" => "pubid:etsi:corrigendum",
          "number" => 1,
          "base" => {
            "_type" => "pubid:etsi:etsi-standard",
            "type" => "ETR",
            "number" => "053",
            "version" => "2",
            "is_edition" => true,
            "year" => "1997",
            "month" => "03",
          },
        )
    end
  end

  # `parts` is now a plain attribute, so exclude() reaches it directly. It must
  # reset to [] rather than nil, or a part-less reference (whose parts default
  # to []) would stop matching a parted one. Covered further in
  # spec/pubid/etsi/part_exclusion_spec.rb.
  describe "#exclude(:part) with split columns" do
    subject(:excluded) do
      Pubid::Etsi.parse("ETSI EN 300 175-1 V1.9.1 (2005-09)").exclude(:part)
    end

    it "clears parts to an empty array, not nil" do
      expect(excluded.parts).to eq([])
    end

    it "keeps the number" do
      expect(excluded.number).to eq("300 175")
    end
  end
end
