# frozen_string_literal: true

require "spec_helper"

# Populate the registry at collection time so the per-flavor examples below are
# generated for every registered flavor (flavor_names is empty until loaded).
Pubid.eager_load_flavors!

# Cross-flavor guard for the "every parser accepts a partial reference"
# invariant. relaton looks a document up by a bare reference (one that omits the
# trailing publication date / version / year) and matches a whole catalogue
# collection via `matches?(row, ignore: [...])`. That only works if the partial
# ref *parses*, leaving the omitted component nil. This spec locks the invariant
# so a newly-added flavor cannot silently regress it — mirroring the
# registry-driven `spec/pubid/prefixes_spec.rb` and
# `spec/pubid/parse_interface_spec.rb`.
#
# `matches?` semantics are covered per-flavor (e.g.
# spec/pubid/etsi/partial_spec.rb); here we only assert parse + nil-omitted.
RSpec.describe "partial reference parsing (cross-flavor)" do
  # One bare/partial reference per registered flavor, plus the attribute(s) it
  # omits (asserted nil). Keyed by the registry's lowercased string flavor name
  # (so "3gpp", "cen" and "cen_cenelec" all appear). Flavors whose natural
  # reference carries no separable date/version omit nothing (`omits: []`): the
  # example is then just a "the bare form still parses" regression guard.
  PARTIAL_REFS = {
    "iso" => { ref: "ISO 9001", omits: [:year] },
    "iec" => { ref: "IEC 60601", omits: [:year] },
    "etsi" => { ref: "ETSI EN 300 175", omits: %i[version date] },
    "nist" => { ref: "NIST SP 800-53", omits: [:year] },
    "ieee" => { ref: "IEEE 802.3", omits: [:year] },
    "itu" => { ref: "ITU-T G.711", omits: %i[date version] },
    "gost" => { ref: "ГОСТ 34.201", omits: [:year] },
    "bsi" => { ref: "BS 5839", omits: [:year] },
    "cen_cenelec" => { ref: "EN 13485", omits: [:year] },
    "cen" => { ref: "EN 13485", omits: [:year] },
    "calconnect" => { ref: "CC 11001", omits: [:date] },
    "jcgm" => { ref: "JCGM 100", omits: [:date] },
    "bipm" => { ref: "CCTF REC 2", omits: [:year] },
    "csa" => { ref: "CSA Z299.1", omits: [:year] },
    "ashrae" => { ref: "ASHRAE 15", omits: [:year] },
    "cie" => { ref: "CIE 015", omits: [:year] },
    "idf" => { ref: "IDF 148-1", omits: [:year] },
    "oiml" => { ref: "OIML V 1", omits: [:date] },
    "jis" => { ref: "JIS A 0001", omits: [:year] },
    "ansi" => { ref: "ANSI C135.14", omits: [:year] },
    "asme" => { ref: "ASME B18.3", omits: [:year] },
    "api" => { ref: "API 1509", omits: [:year] },
    "easc" => { ref: "ПМГ 126", omits: [:year] },
    "astm" => { ref: "ASTM A6", omits: [:year] },
    "iho" => { ref: "IHO P-5", omits: [:version] },
    "oasis" => { ref: "OASIS EDXL", omits: [:version] },
    "sae" => { ref: "SAE AIR1936", omits: [:date] },
    "adobe" => { ref: "Adobe TN 5014", omits: [] },
    "iana" => { ref: "IANA calipso", omits: [] },
    "xsf" => { ref: "XEP 0001", omits: [] },
    "ietf" => { ref: "STD 3", omits: [] },
    "ccsds" => { ref: "CCSDS 121.0-B-1", omits: [] },
    # ECMA carries the edition and volume as separable trailing suffixes
    # (" ed3", " vol2"), so a bare reference leaves both nil and wildcards every
    # edition under `matches?(row, ignore: %i[edition volume])`.
    "ecma" => { ref: "ECMA TR/18", omits: %i[edition volume] },
    "plateau" => { ref: "PLATEAU Technical Report #00", omits: [] },
    "iala" => { ref: "S1070", omits: [] },
    # OGC: the "<yy>" year is the mandatory leading field of the "<yy>-<nnn>"
    # number, so there is no dateless partial form to construct.
    "ogc" => { ref: "24-032r1", omits: [] },
    # AMCA genuinely REQUIRES the trailing "-YY" year today, so no partial form
    # parses yet — partial-ref support for it is future laggard work. Use the
    # canonical full form as a plain "still parses" regression guard
    # (omits: []) until that lands.
    "amca" => { ref: "AMCA Publication 211-22", omits: [] },
    # 3GPP: both trailing qualifiers are separable — ":<release>" and
    # "/<version>" are each optional, so a bare document reference parses with
    # both nil.
    "3gpp" => { ref: "3GPP TS 23.207", omits: %i[release version] },
    # W3C: the publication date is an optional, separable trailing "-YYYYMMDD"
    # group; a type+code reference with no date parses with date nil.
    "w3c" => { ref: "W3C NOTE-xml-names", omits: [:date] },
    # GB: year is the trailing "-YYYY" group, separable.
    "gb" => { ref: "GB/T 20223", omits: [:year] },
    # OMG: identifier has no separable date; the bare acronym form parses.
    "omg" => { ref: "OMG UML", omits: [] },
    # UN: identifier has no separable date; the bare committee path parses.
    "un" => { ref: "TRADE/WP.4/1068", omits: [] },
    # DOI: identifier has no separable date.
    "doi" => { ref: "doi:10.1000/182", omits: [] },
    # ISBN: identifier has no separable date.
    "isbn" => { ref: "ISBN 978-3-16-148410-0", omits: [] },
  }.freeze

  it "has a partial-ref entry for every registered flavor" do
    missing = Pubid::Registry.flavor_names - PARTIAL_REFS.keys
    expect(missing).to be_empty,
                       "add a PARTIAL_REFS entry for: #{missing.join(', ')}"
  end

  it "has no stale entry for an unregistered flavor" do
    stale = PARTIAL_REFS.keys - Pubid::Registry.flavor_names
    expect(stale).to be_empty,
                     "remove stale PARTIAL_REFS entry: #{stale.join(', ')}"
  end

  PARTIAL_REFS.each do |flavor, spec|
    it "#{flavor} parses the partial reference #{spec[:ref].inspect}" do
      id = Pubid::Registry.get(flavor).parse(spec[:ref])
      expect(id).to be_a(Pubid::Identifier)
      spec[:omits].each do |attr|
        expect(id.public_send(attr)).to(
          be_nil, "expected #{flavor} ##{attr} to be nil for the partial ref " \
                  "#{spec[:ref].inspect}, got #{id.public_send(attr).inspect}"
        )
      end
    end
  end
end
