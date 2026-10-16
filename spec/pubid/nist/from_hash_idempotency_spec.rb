# frozen_string_literal: true

require "spec_helper"

# Regression net for the `from_hash`/`to_hash` round-trip idempotency bug.
#
# `parse(str).to_hash` omits the defaulted attributes `all_parts` and
# `publisher_was_parsed`, but `from_hash` used to materialize those defaults
# (lutaml assigns them during deserialization), so `from_hash(clean).to_hash`
# re-emitted them — breaking the exact-equality round-trip relaton-index relies
# on (`from_hash(raw).to_hash == raw`), which discards the whole NIST index-v2.
#
# The fix makes `to_hash` canonical: a defaulted attribute at its default/empty
# value is never serialized, so output is identical whether the id came from
# `parse` or `from_hash`.
RSpec.describe "NIST from_hash/to_hash idempotency" do
  # Attributes that were re-emitted by the buggy from_hash even when the parse
  # hash omitted them (both defaulted, render_default: false).
  let(:defaulted_keys) { %w[all_parts publisher_was_parsed] }

  # Base-class NBS/NIST series (no dedicated subclass) — the 859-row case — plus
  # a couple that resolve to concrete subclasses, which must round-trip too. The
  # trailing three carry a Components::Supplement whose defaulted has_revision
  # (false) used to leak one level down, past the top-level canonicalizer.
  samples = [
    "NBS BSS 0",           # base-class Pubid::Nist::Identifier
    "NBS CIRC 25",
    "NBS FIPS 140",
    "NIST SP 800-53r5",    # SpecialPublication subclass
    "NIST IR 8259",
    "NBS BMS 17sup2",      # nested supplement (has_revision default false)
    "NIST VTS 100-2sup1",
    "NIST VTS 100-3pt2sup1",
  ].freeze

  samples.each do |str|
    context str.inspect do
      let(:parsed) { Pubid::Nist::Identifier.parse(str) }
      let(:parsed_hash) { parsed.to_hash }

      it "round-trips to_hash idempotently through from_hash" do
        restored = Pubid::Nist::Identifier.from_hash(parsed_hash)
        expect(restored.to_hash).to eq(parsed_hash)
      end

      it "reconstructs an equal identifier from the parse hash" do
        restored = Pubid::Nist::Identifier.from_hash(parsed_hash)
        expect(restored).to eq(parsed)
        expect(restored.to_hash).to eq(parsed.to_hash)
      end

      it "does not inject defaulted attributes the parse hash omitted" do
        restored_hash = Pubid::Nist::Identifier.from_hash(parsed_hash).to_hash
        defaulted_keys.each do |key|
          next if parsed_hash.key?(key)

          expect(restored_hash).not_to have_key(key)
        end
      end
    end
  end

  # Nested-component leak: a Components::Supplement's defaulted has_revision
  # (false) must not appear in the serialized supplement sub-hash — lutaml
  # serializes nested components via its own transform, bypassing their public
  # to_hash, so the canonicalizer has to recurse from the parent.
  describe "nested supplement has_revision" do
    ["NBS BMS 17sup2", "NIST VTS 100-2sup1",
     "NIST VTS 100-3pt2sup1"].each do |str|
      it "omits has_revision from #{str.inspect} when it is the default" do
        hash = Pubid::Nist::Identifier.parse(str).to_hash
        expect(hash["supplement"]).not_to have_key("has_revision")
        expect(Pubid::Nist::Identifier.from_hash(hash).to_hash).to eq(hash)
      end
    end

    it "preserves a non-default has_revision (true) through the round-trip" do
      id = Pubid::Nist::Identifier.parse("NBS CIRC 25suprev")
      expect(id.supplement.has_revision).to be true

      hash = id.to_hash
      expect(hash["supplement"]).to include("has_revision" => true)
      expect(Pubid::Nist::Identifier.from_hash(hash).to_hash).to eq(hash)
    end
  end
end

RSpec.describe "NIST from_hash legacy component-era rows" do
  subject(:identifier) { Pubid::Nist::Identifier.from_hash(row) }

  # The pre-flattening pubid-nist serialized the number as a
  # {"value" => …} Hash (Components::Code); the attribute is a plain
  # string now, so from_hash must collapse the legacy shape before the
  # string assignment dumps it (pubid#540).
  let(:row) do
    {"_type" => "pubid:nist:interagency-report",
     "number" => {"value" => "8200"},
     "publisher" => "NIST",
     "series" => {"value" => "IR"}}
  end

  it "collapses the legacy hash number onto the scalar" do
    expect(identifier.number).to eq("8200")
    expect(identifier.to_s).to eq("NIST IR 8200")
  end

  it "keeps the legacy parted number lossless in the render" do
    row["number"] = {"value" => "8200-1", "part" => "1"}
    row["series"] = "IR"

    expect(identifier.number).to eq("8200-1")
    expect(identifier.to_s).to eq("NIST IR 8200-1")
  end
end
