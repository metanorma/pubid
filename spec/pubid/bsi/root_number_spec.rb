# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for BSI.
#
# Relaton::Index::Type#candidates_by_number sorts and bsearches every index row
# on `id.root.number.to_s`. Forty BSI identifiers keyed "", in two distinct
# shapes that need two distinct fixes.
#
# WRAPPERS (30 ids) — the number is already there, one level down, and `#root`
# just never walked to it. `BundledIdentifier` and `Set` hold their members in
# an `identifiers` collection (the ConsolidatedIdentifier shape, which already
# walks `identifiers.first.root`); `AdoptedEuropeanNorm` holds a CEN object in
# `adopted_identifier`. Its `#number` delegation reached only as far as
# `CenCenelec::Identifiers::EuropeanPrestandard`, which is itself a wrapper —
# so the chain died one level short, and fixing it needed both flavors.
#
# DUPLICATE ATTRIBUTES (10 ids) — `CommitteeDocument#document_number` and
# `StandaloneAmendment#amendment_number` held the document number under a
# private name while the `number` inherited from Bsi::SingleIdentifier stayed
# nil. The duplicate is DELETED and the value moved into `number` (the CSA
# shape), rather than adding a derived `#number` method: `number` is a lutaml
# attribute here, so a method of that name collides with the generated
# accessor. Nothing is retyped — Bsi::SingleIdentifier already declares
# `number` as a Bsi::Components::Code, which is exactly what
# `amendment_number` was.
module BsiIndexKeySpec
  FIXTURE_LINES = Dir
    .glob(File.join(__dir__, "../../fixtures/bsi/**/*.txt"))
    .reject { |f| f.include?("/fail/") }
    .flat_map { |f| File.readlines(f, chomp: true) }
    .map(&:strip).reject(&:empty?).reject { |l| l.start_with?("#") }
    .uniq.freeze

  def self.parsed_corpus
    @parsed_corpus ||= FIXTURE_LINES.filter_map do |line|
      id = begin
        Pubid::Bsi.parse(line)
      rescue StandardError, Parslet::ParseFailed
        nil
      end
      [line, id] if id
    end
  end
end

RSpec.describe "Pubid::Bsi index key (root.number)" do
  describe "wrappers walk #root to the document they wrap" do
    {
      "BS SP 10 & 11:1949" => "10",
      "BS 2SP 68 to BS 2SP 71:1973" => "68",
      "DD ENV ISO 11079:1999" => "11079",
      "DD ENV ISO/TR 13843:2001" => "13843",
    }.each do |ref, key|
      it "#{ref} keys on #{key.inspect}" do
        id = Pubid::Bsi.parse(ref)
        expect(id.root.number.to_s).to eq(key)
      end

      it "#{ref} still renders unchanged" do
        expect(Pubid::Bsi.parse(ref).to_s).to eq(ref)
      end
    end
  end

  describe "leaves that hid the number under a private attribute" do
    {
      "14/30300822 DC" => "30300822",
      "21/30445138 DC" => "30445138",
      "AMD 11015" => "11015",
      "AMD 16019" => "16019",
    }.each do |ref, key|
      it "#{ref} keys on #{key.inspect}" do
        id = Pubid::Bsi.parse(ref)
        expect(id.root.number.to_s).to eq(key)
      end

      it "#{ref} still renders unchanged" do
        expect(Pubid::Bsi.parse(ref).to_s).to eq(ref)
      end

      it "#{ref} round-trips through from_hash(to_hash)" do
        id = Pubid::Bsi.parse(ref)
        h = id.to_hash
        expect(Pubid::Bsi::Identifier.from_hash(h).to_hash).to eq(h)
      end
    end

    it "serializes the committee document number as `number`" do
      id = Pubid::Bsi.parse("14/30300822 DC")
      expect(id.to_hash).not_to have_key("document_number")
      expect(id.number.to_s).to eq("30300822")
    end

    it "serializes the standalone amendment number as `number`" do
      id = Pubid::Bsi.parse("AMD 11015")
      expect(id.to_hash).not_to have_key("amendment_number")
      expect(id.number.to_s).to eq("11015")
    end
  end

  # This block used to pin a KNOWN GAP: a "BS ISO 20400 + ..." set holds
  # Pubid::Iso identifiers, and BSI declared `number`/`part`/`subpart` as its
  # own Bsi::Components::Code, so `to_hash` raised
  # Lutaml::Model::IncorrectModelError (hand-off bsi-set-cross-flavor-type).
  #
  # Retyping those three attributes to :string removed the offending type
  # outright, which closes the gap as a side effect — there is no longer a
  # BSI-specific component for a foreign identifier to mismatch. 74 BSI ids
  # that previously raised on `to_hash` now serialize. The pin turning red is
  # what surfaced this, so it is rewritten to assert the repair.
  describe "Identifiers::Set" do
    subject(:id) { Pubid::Bsi.parse("BS ISO 20400 + BS ISO 44001+BS ISO 44002") }

    it "keys on the first member" do
      expect(id.root.number.to_s).to eq("20400")
    end

    it "serializes instead of raising" do
      expect { id.to_hash }.not_to raise_error
    end

    it "round-trips through from_hash" do
      hash = id.to_hash
      restored = Pubid::Bsi::Identifier.from_hash(hash)

      expect(restored).to be_a(Pubid::Bsi::Identifiers::Set)
      expect(restored.to_hash).to eq(hash)
      expect(restored.to_s).to eq(id.to_s)
    end

    # Note the set's `root` walks into the nested ISO identifier, whose own
    # `number` is still an Iso::Components::Code until tranche 3. `.to_s` is
    # what relaton keys on, so the index contract holds either way.
    it "still reaches an ISO Code through #root" do
      expect(id.root.number).to be_a(Pubid::Iso::Components::Code)
    end
  end

  describe "the whole fixture corpus" do
    it "parses a corpus worth sweeping" do
      expect(BsiIndexKeySpec.parsed_corpus.size).to be >= 1_400
    end

    it "gives every identifier a non-empty root.number" do
      bad = BsiIndexKeySpec.parsed_corpus.select do |_, id|
        id.root.number.to_s.empty?
      end
      expect(bad.map(&:first).first(10)).to eq([])
    end
  end
end
