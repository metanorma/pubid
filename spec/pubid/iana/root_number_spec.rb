# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for IANA, plus the determinism tripwire for the
# `number` attribute.
#
# IMPORTANT: this file is only meaningful under the FULL suite
# (`bundle exec rake`), never `rspec spec/pubid/iana` alone. `number` is
# declared `:string` on the concrete leaf Identifiers::Registry, overriding the
# parent ::Pubid::Identifier's `attribute :number, Components::Code`. CLAUDE.md
# records that doing that on a class the leaf INHERITS from (here
# Pubid::Iana::Identifier) resolves against the parent definition
# nondeterministically under multi-flavor load — the IEEE/IETF lesson: passes
# flavor-only, flips `root.number` to "" under the full suite.
#
# Why it matters: Relaton::Index narrows search candidates by
# `id.root.number.to_s`. Before this change every IANA identifier had a nil
# number, so all 3405 published registry rows shared the empty key "" and the
# binary search degenerated to a linear scan — silently, with no error.
# The index key is the TOP-LEVEL registry slug, so a registry and all of its
# sub-registries cluster into one bucket (655 buckets over the 3405 published
# rows; median 3, max 73). The table deliberately includes the awkward corners
# of the real corpus: dotted OIDs, uppercase, internal underscores and
# multi-number sub-slugs.
module IanaIndexKeySpec
  LONG_REGISTRY = "service-function-chaining-service-function-types"

  KEYS = {
    "IANA calipso" => "calipso",
    "IANA _6lowpan-parameters" => "_6lowpan-parameters",
    "IANA _6lowpan-parameters/lowpan_nhc" => "_6lowpan-parameters",
    "IANA sip-parameters/sip-parameters-13" => "sip-parameters",
    "IANA idna-tables-11.0.0/idna-tables-context" => "idna-tables-11.0.0",
    "IANA smi-numbers/smi-numbers-1.3.6.1.2.1.198.4" => "smi-numbers",
    "IANA smi-numbers/smi-numbers-1.3.101" => "smi-numbers",
    "IANA clue/personType" => "clue",
    "IANA ip-over-IEEE1394/ip-over-IEEE1394-1" => "ip-over-IEEE1394",
    "IANA ipv6-parameters/taggerId-types" => "ipv6-parameters",
    "IANA isis-tlv-codepoints/tlv-149-150" => "isis-tlv-codepoints",
    "IANA openpgp/openpgp-hash-alg-ids-rsa-sig-emsa-pkcs1-v1_5-padding" =>
      "openpgp",
    "IANA #{LONG_REGISTRY}/#{LONG_REGISTRY}-2" => LONG_REGISTRY,
  }.freeze
end

RSpec.describe "Pubid::Iana index key (root.number)" do
  def parse(str)
    Pubid::Iana::Identifier.parse(str)
  end

  # The structural half of the tripwire. The examples below prove the *effect*
  # (a String number) but would still pass in an IANA-only run if the attribute
  # were moved up onto the shared base — that failure is load-order dependent.
  # These two assertions are deterministic: they read the attribute definitions
  # directly, so they fail immediately and always.
  describe "number is declared on the LEAF, not the shared base" do
    it "leaves the shared base's inherited Components::Code number alone" do
      expect(Pubid::Iana::Identifier.attributes[:number].type)
        .to eq(Pubid::Components::Code)
    end

    it "Registry declares its own :string number" do
      expect(Pubid::Iana::Identifiers::Registry.attributes[:number].type)
        .to eq(Lutaml::Model::Type::String)
    end
  end


  describe "root.number is the top-level registry slug" do
    IanaIndexKeySpec::KEYS.each do |ref, key|
      it "#{ref} keys on #{key.inspect}" do
        id = parse(ref)
        expect(id.root.number.to_s).to eq(key)
        expect(id.root.number.to_s).not_to be_empty
      end
    end
  end

  describe "the number attribute resolves as a plain String" do
    # Under a flipped attribute resolution `number` is a Components::Code (or
    # nil), which is exactly what a :string-vs-Components::Code merge produces.
    IanaIndexKeySpec::KEYS.each_key do |ref|
      it "#{ref} carries a String number" do
        id = parse(ref)
        expect(id.number).to be_a(String)
        expect(id.to_hash["number"]).to be_a(String)
      end
    end
  end

  describe "clustering" do
    it "puts a registry and its sub-registries in one bucket" do
      keys = [
        "IANA _6lowpan-parameters",
        "IANA _6lowpan-parameters/lowpan_nhc",
        "IANA _6lowpan-parameters/esc-extension-types",
        "IANA _6lowpan-parameters/_6lowpan-parameters-1",
      ].map { |ref| parse(ref).root.number.to_s }

      expect(keys.uniq).to eq(["_6lowpan-parameters"])
    end

    it "separates distinct registries" do
      expect(parse("IANA calipso").root.number.to_s)
        .not_to eq(parse("IANA edhoc").root.number.to_s)
    end
  end

  describe "every IANA identifier is its own root" do
    IanaIndexKeySpec::KEYS.each_key do |ref|
      it "#{ref} roots to itself" do
        id = parse(ref)
        expect(id.root).to equal(id)
      end
    end
  end

  describe "serialized vocabulary" do
    it "is exactly _type + number for a top registry" do
      expect(parse("IANA calipso").to_hash.keys).to contain_exactly(
        "_type", "number"
      )
    end

    it "is exactly _type + number + sub_registry for a sub-registry" do
      hash = parse("IANA _6lowpan-parameters/lowpan_nhc").to_hash
      expect(hash.keys).to contain_exactly("_type", "number", "sub_registry")
    end

    it "never stores a `registry` key (it is derived from number)" do
      IanaIndexKeySpec::KEYS.each_key do |ref|
        expect(parse(ref).to_hash).not_to have_key("registry")
      end
    end

    it "keeps #registry readable as the top-level slug" do
      id = parse("IANA _6lowpan-parameters/lowpan_nhc")
      expect(id.registry).to eq("_6lowpan-parameters")
      expect(id.sub_registry).to eq("lowpan_nhc")
    end

    it "keeps #registry readable after from_hash" do
      id = parse("IANA _6lowpan-parameters/lowpan_nhc")
      rebuilt = Pubid::Iana::Identifier.from_hash(id.to_hash)
      expect(rebuilt.registry).to eq("_6lowpan-parameters")
      expect(rebuilt.to_s).to eq("IANA _6lowpan-parameters/lowpan_nhc")
    end
  end

  # `registry` is gone as a serialized key and there is no alias, so a row
  # written before this change deserializes with a nil number: lutaml ignores
  # unknown keys, and relaton's `id_supported?` skips its round-trip check for
  # concrete subclasses. Rendering therefore has to be the loud failure.
  describe "a legacy `registry`-shaped hash cannot degrade silently" do
    let(:legacy) do
      Pubid::Iana::Identifier.from_hash(
        "_type" => "pubid:iana:registry",
        "registry" => "_6lowpan-parameters",
        "sub_registry" => "lowpan_nhc",
      )
    end

    it "yields an empty index key" do
      expect(legacy.root.number.to_s).to be_empty
    end

    # All three identity surfaces have to fail, not just to_s: guarding only
    # the printed form still lets every stale row collide on "urn:iana:" and
    # on the bare MR token "iana" — one URN and one filename shared by all of
    # them, which is exactly the silent overwrite this change prevents.
    it "raises rather than rendering a publisher-only string" do
      expect { legacy.to_s }
        .to raise_error(ArgumentError, /empty number|regenerate the index/)
    end

    it "raises rather than emitting a bare urn:iana:" do
      expect { legacy.to_urn }
        .to raise_error(ArgumentError, /empty number|regenerate the index/)
    end

    it "raises rather than emitting a bare MR token" do
      expect { legacy.to_mr_string }
        .to raise_error(ArgumentError, /empty number|regenerate the index/)
    end

    it "raises on to_slug too (it delegates to the MR string)" do
      expect { legacy.to_slug }
        .to raise_error(ArgumentError, /empty number|regenerate the index/)
    end
  end
end
