# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/pubid"

# Compact, index-friendly NIST serialization: the single-value Code components
# (series, number) serialize as bare scalars, and the redundant build artifacts
# (first_number, second_number, edition_component) are dropped — mirroring the
# compact key_value flavors (ISO/ITU/ETSI). The to_hash/from_hash pair stays
# symmetric so the round-trip is idempotent and relaton-index rows still verify.
RSpec.describe "Pubid::Nist compact to_hash" do
  describe "flattening + artifact drop" do
    it "renders series as a bare scalar" do
      h = Pubid::Nist.parse("NIST SP 800-53r5").to_hash
      expect(h["series"]).to eq("SP")
    end

    it "renders number as a bare scalar" do
      h = Pubid::Nist.parse("NIST SP 800-53r5").to_hash
      expect(h["number"]).to eq("800-53")
    end

    it "drops the first_number/second_number build artifacts" do
      h = Pubid::Nist.parse("NIST VTS 400-5").to_hash
      expect(h).not_to have_key("first_number")
      expect(h).not_to have_key("second_number")
      expect(h["series"]).to eq("VTS")
      expect(h["number"]).to eq("400-5")
    end

    it "drops the edition_component alias" do
      h = Pubid::Nist.parse("NBS CIRC 101e2supp").to_hash
      expect(h).not_to have_key("edition_component")
    end

    it "renders volume as a bare scalar" do
      h = Pubid::Nist.parse("NBS CSM v9n10").to_hash
      expect(h["volume"]).to eq("9")
    end

    it "renders SP subseries as a bare scalar" do
      h = Pubid::Nist.parse("NIST SP 800-53r5").to_hash
      expect(h["subseries"]).to eq("800")
    end

    it "drops the revision string alias (edition is the source of truth)" do
      h = Pubid::Nist.parse("NIST SP 800-53r5").to_hash
      expect(h).not_to have_key("revision")
      expect(h["edition"]).to eq("type" => "r", "id" => "5")
    end

    it "keeps a derived revision reader for backward compatibility" do
      # revision is no longer a stored attribute, but the computed reader
      # (derived from edition) still answers so downstream callers keep working.
      expect(Pubid::Nist.parse("NIST SP 800-53r5").revision).to eq("r5")
    end

    it "removes the edition_component attribute entirely" do
      h = Pubid::Nist.parse("NBS CIRC 101e2supp").to_hash
      expect(h).not_to have_key("edition_component")
      expect(Pubid::Nist::Identifier.attributes).not_to have_key(:edition_component)
    end

    it "compacts a nested base document (CircularSupplement wrapper)" do
      h = Pubid::Nist.parse("NBS LC 118supp3/1926").to_hash
      expect(h["series"]).to eq("LCIRC")
      expect(h["base"]).to include("series" => "LCIRC", "number" => "118")
      expect(h["base"]).not_to have_key("first_number")
    end
  end

  describe "round-trip idempotency through the compact hash" do
    samples = [
      "NIST SP 800-53r5", "NIST VTS 400-5", "NIST FIPS 197",
      "NBS CIRC 24e7sup2", "NIST GCR 15-917-34", "NBS CRPL 4-m-5",
      "NBS BRPD-CRPL-D 5-2-3-1", "NBS LC 118supp3/1926", "NIST IR 8165",
      "NBS CSM v9n10",
    ]
    samples.each do |ref|
      it "round-trips #{ref.inspect} (== and idempotent hash)" do
        id = Pubid::Nist.parse(ref)
        h  = id.to_hash
        rt = Pubid::Nist::Identifier.from_hash(h)
        expect(rt).to eq(id)
        expect(rt.to_s).to eq(id.to_s)
        expect(rt.to_hash).to eq(h)
      end
    end
  end

end
