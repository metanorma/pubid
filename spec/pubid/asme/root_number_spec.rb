# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for ASME, plus the structural tripwire for the
# `number` attribute.
#
# Relaton::Index::Type#candidates_by_number sorts and bsearches every index row
# on `id.root.number.to_s`. ASME kept identity in an Asme::Components::Code
# under a `code` attribute and never set the `number` it inherits from
# ::Pubid::Identifier, so all 731 parseable fixture ids keyed "".
#
# Asme::Components::Code is NOT a subclass of Pubid::Components::Code, so naming
# the attribute `number` retypes the inherited one — the multi-flavor
# determinism landmine. It is therefore declared on the concrete LEAF
# (Identifiers::Standard) and never on SingleIdentifier or Identifiers::Base,
# which it inherits from. Only meaningful under the full `bundle exec rake`.
#
# `number` holds the WHOLE printed code ("B18.3", "BPVC-CC-BPV"), NOT a
# designator/number split. The split cannot key this corpus: 152 of the 731
# fixture ids are Boiler and Pressure Vessel Code documents whose entire
# identity is the designator, with no numeric part to split off. See the
# comment on Identifiers::Standard#number.
#
# Carries ASME's corpus sweep too: spec/pubid/asme/fixtures_spec.rb globs
# "../../../fixtures/ASME/..." and reports 0 examples (hand-off
# ten-dead-fixture-specs).
module AsmeIndexKeySpec
  # printed reference => index key (the WHOLE printed code)
  KEYS = {
    "ASME B18.3-2012" => "B18.3",
    "ASME A112.19.12-2006" => "A112.19.12",
    "ASME Y14.43-2011" => "Y14.43",
    "ASME A112.19.1/CSA B45.2-2018" => "A112.19.1",
    # Boiler and Pressure Vessel Code documents have no numeric part at all —
    # their whole identity is the designator. Keying on the whole code is what
    # lets these 152 corpus ids have a key rather than an empty string.
    "ASME BPVC-CC-BPV-2019" => "BPVC-CC-BPV",
    "ASME BPVC COMPLETE CODE BIND-2019" => "BPVC COMPLETE CODE BIND",
  }.freeze

  FIXTURE_LINES = Dir
    .glob(File.join(__dir__, "../../fixtures/asme/**/*.txt"))
    .reject { |f| f.include?("/fail/") }
    .flat_map { |f| File.readlines(f, chomp: true) }
    .map(&:strip).reject(&:empty?).reject { |l| l.start_with?("#") }
    .uniq.freeze

  def self.parsed_corpus
    @parsed_corpus ||= FIXTURE_LINES.filter_map do |line|
      id = begin
        Pubid::Asme.parse(line)
      rescue StandardError, Parslet::ParseFailed
        nil
      end
      [line, id] if id
    end
  end
end

RSpec.describe "Pubid::Asme index key (root.number)" do
  describe "structural tripwire (full-suite only)" do
    it "declares `number` as a String on the Standard LEAF" do
      expect(Pubid::Asme::Identifiers::Standard.attributes[:number].type)
        .to eq(Lutaml::Model::Type::String)
    end

    it "leaves the inherited-from classes' `number` untouched" do
      [Pubid::Asme::Identifier, Pubid::Asme::SingleIdentifier,
       Pubid::Asme::Identifiers::Base].each do |klass|
        expect(klass.attributes[:number].type).to eq(Pubid::Components::Code)
      end
    end

    it "no longer declares a `code` attribute" do
      expect(Pubid::Asme::SingleIdentifier.attributes).not_to have_key(:code)
      expect(Pubid::Asme::Identifiers::Standard.attributes)
        .not_to have_key(:code)
    end
  end

  describe "per-type index key" do
    AsmeIndexKeySpec::KEYS.each do |ref, number|
      context ref do
        subject(:id) { Pubid::Asme.parse(ref) }

        it "keys on #{number.inspect}" do
          expect(id.root.number.to_s).to eq(number)
        end

        it "renders the printed code from the number alone" do
          expect(id.to_s).to include(number)
        end
      end
    end
  end

  describe "the whole fixture corpus" do
    it "parses a corpus worth sweeping" do
      expect(AsmeIndexKeySpec.parsed_corpus.size).to be >= 731
    end

    it "gives every identifier a non-empty root.number" do
      bad = AsmeIndexKeySpec.parsed_corpus.select do |_, id|
        id.root.number.to_s.empty?
      end
      expect(bad.map(&:first).first(5)).to eq([])
    end

    it "round-trips every identifier through from_hash(to_hash)" do
      bad = AsmeIndexKeySpec.parsed_corpus.select do |_, id|
        h = id.to_hash
        Pubid::Asme::Identifier.from_hash(h).to_hash != h
      end
      expect(bad.map(&:first).first(5)).to eq([])
    end

    # to_slug is an output FILENAME. Before the index columns landed all 731
    # ids collapsed onto five slugs, 722 of them sharing "asme".
    it "gives every identifier a non-empty, filename-safe MR slug" do
      slugs = AsmeIndexKeySpec.parsed_corpus.map { |_, id| id.to_mr_string }
      expect(slugs.count(&:empty?)).to eq(0)
      expect(slugs.grep(/[^a-z0-9._-]/).first(5)).to eq([])
    end

    it "gives distinct identifiers distinct slugs" do
      by_slug = AsmeIndexKeySpec.parsed_corpus
        .group_by { |_, id| id.to_mr_string }
      clashing = by_slug.reject do |_, rows|
        rows.map { |_, id| id.to_hash }.uniq.size == 1
      end
      # KNOWN GAP, pre-existing, pinned below rather than papered over.
      expect(clashing.keys).to eq(["asme.bpvc-cc-bpv"])
    end

    # Two pre-existing parser gaps meet on the Boiler and Pressure Vessel Code
    # change-record documents, and neither is this branch's to fix:
    #
    #   * the year is dropped ("ASME BPVC.CC.BPV-2021" and "-2023" produce
    #     IDENTICAL hashes, so pubid cannot tell the editions apart at all);
    #   * the same document is spelled with dots and with dashes
    #     ("BPVC-CC-BPV" vs "BPVC.CC.BPV") and nothing normalises the two, so
    #     they are two identifiers that the slug's charset filter maps together.
    #
    # Pinned so a fix to either trips this. See hand-off
    # asme-bpvc-and-amca-residue.
    it "still cannot distinguish the BPVC change-record spellings" do
      dashed = Pubid::Asme.parse("ASME BPVC-CC-BPV-2019")
      dotted = Pubid::Asme.parse("ASME BPVC.CC.BPV-2021")
      expect(dashed.year).to be_nil
      expect(dotted.year).to be_nil
      expect(dashed.to_mr_string).to eq(dotted.to_mr_string)
      expect(dashed.to_hash).not_to eq(dotted.to_hash)
    end
  end

  # The serialized code was a NESTED hash; it is now flat scalars, which is
  # what an index row wants. No relaton-data-asme exists, so nothing published
  # has to migrate.
  describe "serialized shape" do
    it "emits flat scalars instead of a nested code hash" do
      expect(Pubid::Asme.parse("ASME B18.3-2012").to_hash)
        .to eq(
          "_type" => "pubid:asme:standard",
          "publisher" => "ASME",
          "number" => "B18.3",
          "year" => "2012",
        )
    end
  end
end
