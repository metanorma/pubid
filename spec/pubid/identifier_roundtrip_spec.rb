# frozen_string_literal: true

require "spec_helper"

# Phase 0 safety net for the identifier-hierarchy unification
# (plans/exlpore-why-in-the-misty-hennessy.md).
#
# Asserts that for every flavor, `parse -> to_hash -> from_hash` reconstructs an
# equal identifier (same concrete class, same canonical string). This is the
# regression net the refactor leans on: promoting a shared polymorphic
# `from_hash` onto the base, and converting every flavor's Identifier into a
# real Pubid::Identifier subclass, must not change any of these round-trips.
#
# Flavors whose serialization is currently broken are listed in
# PENDING_ROUND_TRIP and marked `pending`. RSpec reports a pending example that
# still fails as pending (suite stays green); once a Phase 3 fix lands and the
# example passes, RSpec FAILS it ("expected pending to fail") — that red is the
# signal to delete the marker. Do not remove a PENDING_ROUND_TRIP entry until
# its flavor actually round-trips.
RSpec.describe "Identifier to_hash/from_hash round-trip" do
  # flavor module => a simple, canonical, parseable identifier for that flavor.
  ROUND_TRIP_SAMPLES = {
    "Pubid::Amca"       => "AMCA 200",
    "Pubid::Ansi"       => "ANSI 802.3-2012",
    "Pubid::Api"        => "API BULL 11L2",
    "Pubid::Ashrae"     => "ASHRAE 55-2017",
    "Pubid::Asme"       => "ASME B18.3-2012",
    "Pubid::Astm"       => "ASTM ADJD2148",
    "Pubid::Bsi"        => "BS 5839-1:2017",
    "Pubid::Ccsds"      => "CCSDS 100.0-G-1",
    "Pubid::CenCenelec" => "EN 50128:2011",
    "Pubid::Cie"        => "CIE 198:2011",
    "Pubid::Csa"        => "CSA C22.2 NO. 0:20",
    "Pubid::Etsi"       => "ETSI EG 200 053 V1.5.1 (2004-06)",
    "Pubid::Idf"        => "IDF 146:2003",
    "Pubid::Iec"        => "IEC 60050:2011",
    "Pubid::Ieee"       => "IEEE 802.3-2018",
    "Pubid::Iana"       => "IANA _6lowpan-parameters",
    "Pubid::Iho"        => "IHO S-57",
    "Pubid::Ietf"       => "RFC 2119",
    "Pubid::Iso"        => "ISO 9001:2015",
    "Pubid::Itu"        => "ITU-T G.711",
    "Pubid::Jcgm"       => "JCGM 100:2008",
    "Pubid::Jis"        => "JIS A 0001:1999",
    "Pubid::Nist"       => "NIST IR 88-4008",
    "Pubid::Ogc"        => "24-032r1",
    "Pubid::Oiml"       => "OIML R 138",
    "Pubid::Plateau"    => "PLATEAU Handbook #00",
    "Pubid::Sae"        => "SAE J1939",
    "Pubid::Tgpp"       => "TS 23.207:REL-4/2.0.0",
  }.freeze

  # Known-broken round-trips, to be fixed in Phase 3 (fix all 8). Value is the
  # reason, shown in the pending output.
  # Remaining broken round-trips after the hierarchy unification. The publisher
  # crash is fixed for all of these, but their custom component attributes
  # (code/version/sector/series/type/year objects) still need per-flavor
  # key_value mappings to round-trip. Tracked here; identity (is_a?) works.
  PENDING_ROUND_TRIP = {
  }.freeze

  ROUND_TRIP_SAMPLES.each do |flavor_const, sample|
    it "#{flavor_const} round-trips #{sample.inspect}" do
      pending(PENDING_ROUND_TRIP[flavor_const]) if PENDING_ROUND_TRIP.key?(flavor_const)

      flavor = Object.const_get(flavor_const)
      id = flavor.parse(sample)
      restored = id.class.from_hash(id.to_hash)

      expect(restored.class).to eq(id.class)
      expect(restored.to_s).to eq(id.to_s)

      # to_hash is canonical: from_hash must not re-introduce defaulted
      # attributes (all_parts, publisher_was_parsed, ...) that parse omitted,
      # so the serialized hash round-trips idempotently. relaton-index relies on
      # this exact-equality check to validate every stored index row.
      expect(restored.to_hash).to eq(id.to_hash)
    end
  end

  # CSA's general forms round-trip (covered above), but the CAN/CSA adoption +
  # revision form does not yet. It is a WrapperIdentifier (a plain
  # Lutaml::Model::Serializable, not a Pubid::Identifier) whose nested
  # `wrapped_identifier` is an attr_accessor — invisible to serialization, so it
  # is nil after from_hash. Making it a polymorphic lutaml attribute is the right
  # shape, but it needs (a) cross-flavor `_type` dispatch for the nested id
  # (CanadianAdopted wraps CSA, CsaAdopted wraps ISO/IEC/CISPR), which the
  # static class_map doesn't resolve cleanly, and (b) a fix for
  # CanadianAdopted#to_s, which references `original_reaffirmation_4digit` on
  # itself (it lives on the wrapped id). Tracked separately; the working CSA
  # forms stay protected by the suite above.
  describe "CSA CAN/CSA adoption+revision form" do
    it "round-trips CAN/CSA-A123.2-03 (R2023)" do
      pending "wrapped_identifier (attr_accessor on a Lutaml wrapper) is not " \
              "serialized; needs polymorphic nested-id dispatch + a to_s fix"
      id = Pubid::Csa.parse("CAN/CSA-A123.2-03 (R2023)")
      restored = id.class.from_hash(id.to_hash)
      expect(restored.to_s).to eq(id.to_s)
    end
  end
end
