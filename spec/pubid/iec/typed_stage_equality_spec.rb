# frozen_string_literal: true

require "spec_helper"

# `from_hash(to_hash) == parse` used to be false for EVERY IEC identifier.
#
# `to_s`, `to_urn` and `to_hash` all agreed, so the relaton index gate
# (`from_hash(to_hash) == to_hash`) passed and nothing raised. Only `==` saw it
# — and `#matches?` is `exclude(*ignore) == other.exclude(*ignore)`, so a
# relaton lookup (a parsed reference against a `from_hash`-ed row) silently
# returned nothing.
#
# Two independent causes, both of one family: a `from_hash` default that
# produces a different value from the parse path.
#
#   1. `typed_stage.original_abbr` was written by the attribute default and by
#      `stage_from_kv`, but never by the parse path.
#   2. `Amendment` / `Corrigendum` redeclared `attribute :type` with a default
#      that returns the Symbol `:amd` / `:cor`, where the parse path assigns a
#      `Pubid::Components::Type`.
RSpec.describe "Pubid::Iec typed_stage / type equality" do
  # One form per construct that fills `typed_stage` differently.
  REFERENCES = [
    "IEC 60601",                             # published, undated
    "IEC 60050:2011",                        # published, dated
    "IEC CDV 60601",                         # draft stage
    "IEC TS 62443-1-1:2009",                 # typed document
    "IEC 61000-4-2:2008/AMD1:2017",          # amendment
    "IEC 60050-300:2001+AMD1:2005 CSV",      # consolidated
    "IEC/IEEE 82079-1:2019",                 # co-published
    "CISPR 12:2007/AMD1:2009",               # amendment, non-IEC publisher
    "CISPR 16-4-2:2011/AMD2:2018/COR1:2019", # corrigendum of an amendment
    "IEC 60050-111/AMD1/FRAG1 ED2",          # fragment
    "CISPR 11:1975+AMD1:1976 CSV",           # VapIdentifier
    "IEC 60695-2-1/1:1994",                  # SheetIdentifier
    "IEC 60050-300:2001/DAM1",               # amendment at a draft stage
  ].freeze

  REFERENCES.each do |reference|
    context reference.inspect do
      subject(:id) { Pubid::Iec.parse(reference) }

      let(:row) { Pubid::Iec::Identifier.from_hash(id.to_hash) }

      it "restores an equal identifier" do
        expect(row).to eq(id)
      end

      it "matches its own row when the year is ignored" do
        expect(id.matches?(row, ignore: [:year])).to be true
      end

      # original_abbr is not serialized, so the parsed spelling cannot survive a
      # round trip. Both paths must therefore converge on nil.
      it "leaves typed_stage.original_abbr nil on both paths" do
        expect(id.typed_stage&.original_abbr).to be_nil
        expect(row.typed_stage&.original_abbr).to be_nil
      end
    end
  end

  describe "Amendment and Corrigendum #type" do
    {
      "IEC 61000-4-2:2008/AMD1:2017" => "amd",
      "CISPR 16-4-2:2011/AMD2:2018/COR1:2019" => "cor",
    }.each do |reference, type_code|
      it "is a Components::Type, not a Symbol, for #{reference.inspect}" do
        id = Pubid::Iec.parse(reference)
        row = Pubid::Iec::Identifier.from_hash(id.to_hash)

        [id, row].each do |identifier|
          expect(identifier.type).to be_a(Pubid::Components::Type)
          expect(identifier.type.type_code.to_s).to eq(type_code)
        end
      end
    end

    # `Builder#wrap_with_consolidated` builds the supplement directly and never
    # calls `assign_attributes`, so the deleted attribute default fired on the
    # PARSE path too — a consolidated amendment's `type` was the bare Symbol
    # `:amd`, not a Components::Type. Removing the declaration repairs that as
    # well, so lock the parse path here, not only the round trip.
    it "is a Components::Type for a consolidated amendment member" do
      id = Pubid::Iec.parse("IEC 60050-300:2001+AMD1:2005 CSV")
      amendment = id.base.identifiers.last

      expect(amendment).to be_a(Pubid::Iec::Identifiers::Amendment)
      expect(amendment.type).to be_a(Pubid::Components::Type)
      expect(amendment.type.type_code.to_s).to eq("amd")
    end
  end

  # The fix is a runtime-attribute change only. Nothing serialized moves, so no
  # index migration follows.
  describe "unchanged rendering and serialization surfaces" do
    it "still collapses the long amendment spelling onto the short one" do
      expect(Pubid::Iec.parse("IEC 61000-4-2:2008/Amd 1:2017").to_s)
        .to eq("IEC 61000-4-2:2008/AMD1:2017")
    end

    it "keeps to_s, to_urn and to_hash stable through a round trip" do
      id = Pubid::Iec.parse("IEC TS 62443-1-1:2009")
      row = Pubid::Iec::Identifier.from_hash(id.to_hash)

      expect(row.to_s).to eq("IEC TS 62443-1-1:2009")
      expect(row.to_urn.to_s).to eq(id.to_urn.to_s)
      expect(row.to_hash).to eq(id.to_hash)
    end
  end
end
