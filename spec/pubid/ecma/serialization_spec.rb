# frozen_string_literal: true

require "spec_helper"

# Round-trip invariant for index serialization: a parsed ECMA identifier must
# survive `to_hash` -> `from_hash` unchanged. This is the contract the Relaton
# index relies on (store `id.to_hash`, rebuild via `from_hash`).
RSpec.describe "Pubid::Ecma identifier hash round-trip" do
  refs = {
    "ECMA-411" => "pubid:ecma:standard",
    "ECMA-418-1" => "pubid:ecma:standard",
    "ECMA TR/101" => "pubid:ecma:technical-report",
    "ECMA MEM/1970" => "pubid:ecma:memento",
  }

  refs.each do |ref, type|
    describe ref do
      let(:identifier) { Pubid::Ecma::Identifier.parse(ref) }
      let(:hash) { identifier.to_hash }

      it "serializes to a non-empty hash" do
        expect(hash).not_to be_empty
      end

      it "carries the polymorphic _type #{type.inspect}" do
        expect(hash["_type"]).to eq(type)
      end

      it "rebuilds an equal identifier from its hash" do
        rebuilt = Pubid::Ecma::Identifier.from_hash(hash)
        expect(rebuilt.to_s).to eq(identifier.to_s)
      end

      # The relaton-index contract: to_hash is idempotent through from_hash, so
      # every serialized attribute is preserved exactly.
      it "round-trips to_hash idempotently" do
        expect(Pubid::Ecma::Identifier.from_hash(hash).to_hash).to eq(hash)
      end
    end
  end

  # Edition is relaton's `:ed:`. It serializes into the hash AND prints, because
  # the index keys on a bare `to_s`. See spec/pubid/ecma/edition_volume_spec.rb.
  describe "edition (the relaton :ed: contract)" do
    let(:identifier) do
      Pubid::Ecma::Identifiers::Standard.new(number: "434", edition: "1")
    end
    let(:hash) { identifier.to_hash }

    it "serializes edition into the hash" do
      expect(hash["edition"]).to eq("1")
    end

    it "round-trips edition through from_hash" do
      expect(Pubid::Ecma::Identifier.from_hash(hash).edition).to eq("1")
    end

    it "renders edition in the printed string" do
      expect(identifier.to_s).to eq("ECMA-434 ed1")
    end

    it "omits edition from the printed string on request" do
      expect(identifier.to_s(with_edition: false)).to eq("ECMA-434")
    end
  end

  # Volume is relaton's `:vol:`. Only ECMA-269 ed3 needs it — its four volumes
  # share one docidentifier and one title, so the volume is the ONLY thing that
  # separates those four index rows.
  describe "volume (the relaton :vol: contract)" do
    let(:identifier) do
      Pubid::Ecma::Identifiers::Standard.new(
        number: "269", edition: "3", volume: "2",
      )
    end
    let(:hash) { identifier.to_hash }

    it "serializes volume into the hash" do
      expect(hash["volume"]).to eq("2")
    end

    it "round-trips volume through from_hash" do
      expect(Pubid::Ecma::Identifier.from_hash(hash).volume).to eq("2")
    end

    it "renders volume in the printed string" do
      expect(identifier.to_s).to eq("ECMA-269 ed3 vol2")
    end

    it "omits volume from the printed string on request" do
      expect(identifier.to_s(with_volume: false)).to eq("ECMA-269 ed3")
    end
  end

  # Unset edition and volume must drop out of the canonical hash entirely.
  describe "an identifier without an edition or a volume" do
    let(:hash) { Pubid::Ecma::Identifier.parse("ECMA-411").to_hash }

    it "does not include an edition key" do
      expect(hash).not_to have_key("edition")
    end

    it "does not include a volume key" do
      expect(hash).not_to have_key("volume")
    end
  end
end
