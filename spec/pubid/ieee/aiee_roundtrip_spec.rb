# frozen_string_literal: true

require "spec_helper"

# AIEE identifiers were serialized with a nested `code` object and no `_type`,
# so `Pubid::Ieee::Identifier.from_hash(to_hash)` couldn't route back to
# `Aiee::Identifier` and dropped the code entirely — every AIEE row failed the
# relaton index-v2 round-trip gate (from_hash(to_hash) != to_hash) and had a nil
# `root.number`. Reparenting AIEE onto `Pubid::Ieee::Identifier` + `CodeNumber`
# gives it the same flat split-columns (number/prefix/parts/separator), a
# `_type` (pubid:ieee:aiee), and polymorphic from_hash routing.
# (hand-off: ieee-numberless-standard-parse roadmap item 1.)
RSpec.describe "AIEE flat-column round-trip" do
  subject(:klass) { Pubid::Ieee::Identifier }

  # ref => [canonical to_s, bare root.number]
  {
    "AIEE No 13-1930" => ["AIEE No 13-1930", "13"],
    "AIEE No 1B-1944" => ["AIEE No 1B-1944", "1B"],
    "AIEE No 20A-1946" => ["AIEE No 20A-1946", "20A"],
    "AIEE No 15-1928-05" => ["AIEE No 15-1928-05", "15"], # date-like parts
  }.each do |ref, (canonical, number)|
    context ref.inspect do
      let(:id) { klass.parse(ref) }

      it "parses to an AIEE identifier" do
        expect(id).to be_a(Pubid::Ieee::Aiee::Identifier)
      end

      it "serializes with a distinct _type pubid:ieee:aiee" do
        expect(id.to_hash["_type"]).to eq("pubid:ieee:aiee")
      end

      it "exposes a non-empty root.number (the index key)" do
        expect(id.root.number).to eq(number)
      end

      it "serializes flat columns, not a nested `code`" do
        expect(id.to_hash).not_to have_key("code")
        expect(id.to_hash["number"]).to eq(number)
      end

      it "round-trips through to_hash/from_hash" do
        h = id.to_hash
        expect(klass.from_hash(h).to_hash).to eq(h)
      end

      it "renders identically after a from_hash round-trip" do
        expect(klass.from_hash(id.to_hash).to_s).to eq(id.to_s)
      end

      it "still renders the canonical to_s" do
        expect(id.to_s).to eq(canonical)
      end
    end
  end

  # A relationship-bearing AIEE id. It now satisfies the relaton index gate —
  # the to_hash round-trips and root.number is non-empty. NOTE: `to_s` render-
  # stability is deliberately NOT asserted here: the shared
  # Pubid::Components::Relationship serializes only `relationship_type` and
  # drops the related-identifier text, so a deserialized relationship renders
  # `()` — a PRE-EXISTING limitation affecting every IEEE type (e.g.
  # "IEEE Std 100-2000 (Revision of IEEE Std 100-1996)"), not something this
  # AIEE change introduced or is scoped to fix.
  context "with a relationship" do
    let(:ref) { "AIEE No 28-1944 (Revision of AIEE 28-1936)" }
    let(:id) { klass.parse(ref) }

    it "parses to an AIEE identifier with a non-empty root.number" do
      expect(id).to be_a(Pubid::Ieee::Aiee::Identifier)
      expect(id.root.number).to eq("28")
      expect(id.to_hash["_type"]).to eq("pubid:ieee:aiee")
    end

    it "round-trips through to_hash/from_hash (the relaton index gate)" do
      h = id.to_hash
      expect(klass.from_hash(h).to_hash).to eq(h)
    end

    it "renders the bare identifier, keeping the relationship on the object" do
      # The descriptive relationship narrative is deliberately kept out of to_s
      # (bounded identifier string); it stays reachable on `relationships`.
      expect(id.to_s).to eq("AIEE No 28-1944")
      expect(id.relationships.first.relationship_type).to eq("revision_of")
    end
  end
end
