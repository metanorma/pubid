# frozen_string_literal: true

require "spec_helper"

# The RFC editor's rfc-index.xml emits ZERO-PADDED doc-ids —
# <doc-id>RFC0001</doc-id>, <is-also><doc-id>STD0066</doc-id></is-also>,
# BCP0009, FYI0036 — and relaton builds the STD/BCP/FYI <-> RFC
# cross-references (relaton#109's headline acceptance
# criterion: "RFC 3986 and STD 66 resolve to one record") from exactly those
# elements. relaton is forbidden from normalizing them itself ("never string
# surgery"), so the padded spellings have to parse here.
#
# This is a NORMALIZING parse: the padded input renders back as the canonical
# unpadded, space-separated form. That is why these strings must NOT appear in
# spec/fixtures/ietf/identifiers/pass/*.txt, which is byte-exact.
RSpec.describe "Pubid::Ietf zero-padded identifiers" do
  # padded (and unspaced) spelling => canonical spelling
  {
    "STD0066" => "STD 66",
    "STD 0066" => "STD 66",
    "STD66" => "STD 66",
    "BCP0009" => "BCP 9",
    "FYI0036" => "FYI 36",
    "RFC0001" => "RFC 1",
    "RFC0791" => "RFC 791",
    "RFC1918" => "RFC 1918",
  }.each do |padded, canonical|
    describe padded do
      let(:parsed) { Pubid::Ietf::Identifier.parse(padded) }
      let(:expected) { Pubid::Ietf::Identifier.parse(canonical) }

      it "renders the canonical unpadded form" do
        expect(parsed.to_s).to eq(canonical)
      end

      it "builds the same class as the canonical spelling" do
        expect(parsed.class).to eq(expected.class)
      end

      it "serializes identically to the canonical spelling" do
        expect(parsed.to_hash).to eq(expected.to_hash)
      end

      it "produces the same URN as the canonical spelling" do
        expect(parsed.to_urn.to_s).to eq(expected.to_urn.to_s)
      end

      it "keys the index bucket identically" do
        expect(parsed.root.number.to_s).to eq(expected.root.number.to_s)
      end
    end
  end

  it "keeps an all-zero number intact rather than emptying it" do
    expect(Pubid::Ietf::Identifier.parse("RFC0000").to_s).to eq("RFC 0")
  end

  context "does not over-accept" do
    it "still rejects trailing garbage after a padded number" do
      expect { Pubid::Ietf::Identifier.parse("STD0066x") }
        .to raise_error(StandardError)
    end

    it "still rejects a series token with no number" do
      expect { Pubid::Ietf::Identifier.parse("STD") }
        .to raise_error(StandardError)
    end

    it "leaves Internet-Draft slugs untouched" do
      # A draft slug can contain digits with leading zeros; nothing here may
      # strip them.
      expect(Pubid::Ietf::Identifier.parse("draft-ietf-quic-transport-00").to_s)
        .to eq("draft-ietf-quic-transport-00")
    end
  end
end
