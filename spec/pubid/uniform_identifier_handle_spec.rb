# frozen_string_literal: true

require "spec_helper"

# Populate the registry at collection time so the per-flavor examples below are
# generated for every registered flavor.
Pubid.eager_load_flavors!

# The unification contract: `Pubid::<Flavor>::Identifier` is the single uniform
# handle for a flavor. It is the common ancestor of every concrete type
# (including wrapper / supplement subtypes) and it hosts the shared polymorphic
# `from_hash`, so a consumer (e.g. relaton's `pubid_class:`) never needs the
# legacy `Identifiers::Base` — `Identifier` is a strict superset.
RSpec.describe "Uniform per-flavor Identifier handle" do
  # One representative reference per flavor. Wrapper/supplement samples are
  # included where a flavor has them, to prove `Identifier` — not `Base` —
  # covers wrappers on `from_hash`.
  samples = {
    "amca"        => ["AMCA 200"],
    "ansi"        => ["ANSI 802.3-2012"],
    "api"         => ["API BULL 11L2"],
    "ashrae"      => ["ASHRAE 55-2017"],
    "asme"        => ["ASME B18.3-2012"],
    "astm"        => ["ASTM ADJD2148"],
    "bsi"         => ["BS 5839-1:2017"],
    "ccsds"       => ["CCSDS 100.0-G-1"],
    "cen_cenelec" => ["EN 50128:2011"],
    "cie"         => ["CIE 198:2011"],
    "csa"         => ["CSA C22.2 NO. 0:20"],
    "etsi"        => ["ETSI EG 200 053 V1.5.1 (2004-06)"],
    "idf"         => ["IDF 146:2003"],
    "iec"         => ["IEC 60050:2011", "IEC 60050-300:2001+AMD1:2005 CSV"],
    "ieee"        => ["IEEE 802.3-2018"],
    "iho"         => ["IHO S-57"],
    "ietf"        => ["RFC 2119", "STD 66", "draft-ietf-quic-transport-34"],
    "iso"         => ["ISO 9001:2015", "ISO 9001:2015/Amd 1:2020"],
    "itu"         => ["ITU-T G.711"],
    "jcgm"        => ["JCGM 100:2008"],
    "jis"         => ["JIS A 0001:1999"],
    "nist"        => ["NIST IR 88-4008"],
    "oiml"        => ["OIML R 138"],
    "plateau"     => ["PLATEAU Handbook #00"],
    "sae"         => ["SAE J1939"],
  }.freeze

  describe "from_hash round-trips through the flavor Identifier handle" do
    samples.each do |flavor_name, refs|
      mod = Pubid::Registry.get(flavor_name)
      next unless mod # skip if not registered in this build

      refs.each do |ref|
        it "#{flavor_name}: #{ref}" do
          id = mod.parse(ref)
          # Every parsed identifier is_a? its flavor Identifier — so a consumer
          # handed the flavor Identifier class can identity-check any subtype.
          expect(id).to be_a(mod::Identifier)
          # The flavor Identifier handle deserializes the canonical hash back to
          # the same canonical hash (polymorphic dispatch via _type), regardless
          # of the concrete subtype (wrapper included). This is the documented
          # idempotence invariant `from_hash(x.to_hash).to_hash == x.to_hash`.
          expect(mod::Identifier.from_hash(id.to_hash).to_hash).to eq(id.to_hash)
        end
      end
    end
  end
end
