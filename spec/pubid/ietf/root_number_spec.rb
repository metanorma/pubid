# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for IETF, plus the determinism tripwire for the
# `number` attribute.
#
# IMPORTANT: this file is only meaningful under the FULL suite
# (`bundle exec rake`), never `rspec spec/pubid/ietf` alone. `number` is
# declared `:string` on the five concrete IETF leaves, overriding the parent
# ::Pubid::Identifier's `attribute :number, Components::Code`. CLAUDE.md records
# that doing that on a class the leaves INHERIT from resolves against the parent
# definition nondeterministically under multi-flavor load (the IEEE lesson:
# passes flavor-only, flips `root.number` to "" under the full suite). Declaring
# it on the leaves is what removes the ambiguity; these examples are what prove
# it stayed removed.
#
# Why it matters: Relaton::Index narrows search candidates by
# `id.root.number.to_s` (Type#candidates_by_number, #bsearch_left/right, and the
# sorts in FileIO that keep the bsearch valid). A nil number yields the empty
# key "" for every row and silently defeats the binary search — no error, just a
# linear scan over 176,862 rows.
RSpec.describe "Pubid::Ietf index key (root.number)" do
  def parse(str)
    Pubid::Ietf::Identifier.parse(str)
  end

  # The structural half of the tripwire. The examples below prove the *effect*
  # (a String number) but would still pass in an IETF-only run if the mixin
  # were moved back up onto the shared base — that failure is load-order
  # dependent. These two assertions are deterministic: they read the attribute
  # definitions directly, so they fail immediately and always if the leaves
  # stop declaring `number` themselves.
  describe "number is declared on the LEAVES, not the shared base" do
    it "leaves the shared base's inherited Components::Code number alone" do
      expect(Pubid::Ietf::Identifier.attributes[:number].type)
        .to eq(Pubid::Components::Code)
    end

    %i[Rfc Bcp Std Fyi InternetDraft].each do |leaf|
      it "#{leaf} declares its own :string number" do
        klass = Pubid::Ietf::Identifiers.const_get(leaf)
        expect(klass.attributes[:number].type)
          .to eq(Lutaml::Model::Type::String)
      end
    end
  end

  describe "the number attribute resolves as a plain String" do
    # Under a flipped attribute resolution `number` is a Components::Code (or
    # nil), which is exactly what a :string-vs-Components::Code merge produces.
    %w[
      RFC\ 2119
      BCP\ 3
      STD\ 66
      FYI\ 1
      draft-ietf-quic-transport-34
      draft-ietf-quic-transport
    ].each do |ref|
      it "#{ref} carries a String number" do
        expect(parse(ref).number).to be_a(String)
      end

      it "#{ref} serializes number as a String" do
        expect(parse(ref).to_hash["number"]).to be_a(String)
      end
    end
  end

  describe "every identifier has a non-empty index key" do
    {
      "RFC 2119" => "2119",
      "RFC 1" => "1",
      "BCP 3" => "3",
      "STD 66" => "66",
      "FYI 1" => "1",
      "draft-giuliano-treedn-02" => "draft-giuliano-treedn",
      "draft-giuliano-treedn" => "draft-giuliano-treedn",
      "draft-adams-cast-256" => "draft-adams-cast-256",
      "draft-ietf-pilc-2.5g3g-12" => "draft-ietf-pilc-2.5g3g",
      "draft-chapin-clnp-ISO8473-00" => "draft-chapin-clnp-ISO8473",
    }.each do |ref, key|
      it "#{ref} keys as #{key.inspect}" do
        expect(parse(ref).root.number.to_s).to eq(key)
      end

      it "#{ref} keys non-empty" do
        expect(parse(ref).root.number.to_s).not_to be_empty
      end
    end
  end

  describe "clustering" do
    it "gives a draft and its unversioned aggregator the same key" do
      expect(parse("draft-ietf-quic-transport-34").root.number)
        .to eq(parse("draft-ietf-quic-transport").root.number)
    end

    it "gives every version of a draft the same key" do
      keys = %w[00 01 34].map do |v|
        parse("draft-ietf-quic-transport-#{v}").root.number
      end
      expect(keys.uniq.size).to eq(1)
    end

    it "gives a padded and an unpadded sub-series id the same key" do
      expect(parse("STD0066").root.number).to eq(parse("STD 66").root.number)
    end
  end

  describe "every IETF identifier is its own root" do
    # IETF has no wrapper/supplement types, so #root is always self and the
    # index key is always the leaf's own number.
    %w[RFC\ 2119 BCP\ 3 STD\ 66 FYI\ 1 draft-giuliano-treedn-02].each do |ref|
      it ref do
        id = parse(ref)
        expect(id.root).to equal(id)
      end
    end
  end

  describe "serialized key sets" do
    # The whole IETF vocabulary is three keys: `_type` and `number` always,
    # `version` only on a versioned draft. `series` is NOT stored — `_type`
    # already encodes it — and `name` is gone (the slug lives in `number`).
    {
      "RFC 2119" => %w[_type number],
      "BCP 3" => %w[_type number],
      "STD 66" => %w[_type number],
      "FYI 1" => %w[_type number],
      "draft-giuliano-treedn" => %w[_type number],
      "draft-giuliano-treedn-02" => %w[_type number version],
    }.each do |ref, keys|
      it "#{ref} serializes exactly #{keys.inspect}" do
        expect(parse(ref).to_hash.keys).to match_array(keys)
      end
    end

    it "never serializes name" do
      expect(parse("draft-giuliano-treedn-02").to_hash).not_to have_key("name")
    end

    it "never serializes series" do
      expect(parse("STD 66").to_hash).not_to have_key("series")
    end

    it "still exposes series as a derived reader" do
      expect(parse("STD 66").series).to eq("STD")
      expect(parse("BCP 3").series).to eq("BCP")
      expect(parse("FYI 1").series).to eq("FYI")
    end

    it "reconstructs series through from_hash" do
      hash = parse("STD 66").to_hash
      expect(Pubid::Ietf::Identifier.from_hash(hash).series).to eq("STD")
    end
  end

  # A pre-`number` index row stored the Internet-Draft slug under `name`.
  # lutaml ignores unknown keys, so such a row deserializes without any error
  # into an identifier whose `number` — and therefore whose index key — is nil.
  # relaton would not catch it either (id_supported? skips the round-trip check
  # for subclasses), so rendering has to be the thing that fails loudly.
  describe "a legacy `name`-shaped hash cannot degrade silently" do
    let(:legacy) do
      Pubid::Ietf::Identifier.from_hash(
        "_type" => "pubid:ietf:internet-draft",
        "name" => "draft-giuliano-treedn",
        "version" => "02",
      )
    end

    it "leaves the index key empty rather than inventing one" do
      expect(legacy.root.number.to_s).to be_empty
    end

    it "raises instead of rendering a partial string" do
      expect { legacy.to_s }
        .to raise_error(ArgumentError, /empty number|regenerate the index/)
    end

    it "raises for the version-less legacy row too" do
      bare = Pubid::Ietf::Identifier.from_hash(
        "_type" => "pubid:ietf:internet-draft",
        "name" => "draft-giuliano-treedn",
      )
      expect { bare.to_s }.to raise_error(ArgumentError)
    end
  end
end
