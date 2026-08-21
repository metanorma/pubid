# frozen_string_literal: true

require "spec_helper"

# Issue #142: distinct identifiers must never collide on `to_mr_string`, and
# the MR doubles as a filename-safe slug (`to_slug`).
#
# Before the `number` attribute existed, EVERY IANA identifier rendered the
# empty MR string "": `mr_number` reads `number` (nil), `mr_type` reads
# `typed_stage` (never set by the builder) and `mr_publisher` reads the
# `publisher` attribute — which IANA deliberately keeps as a plain PUBLISHER
# constant so it cannot shadow the inherited lutaml attribute. All 3405
# published registry rows therefore shared one slug.
#
# The flavor supplies `mr_publisher` and `mr_number_with_part` directly.
# Verified over the whole published corpus: 3405 distinct slugs, charset
# strictly [a-z0-9._-].
RSpec.describe "Pubid::Iana MR string (issue #142)" do
  def parse(str)
    Pubid::Iana::Identifier.parse(str)
  end

  describe "shape" do
    {
      "IANA calipso" => "iana.calipso",
      "IANA _6lowpan-parameters" => "iana._6lowpan-parameters",
      "IANA _6lowpan-parameters/lowpan_nhc" =>
        "iana._6lowpan-parameters.lowpan_nhc",
      "IANA sip-parameters/sip-parameters-13" =>
        "iana.sip-parameters.sip-parameters-13",
      "IANA idna-tables-11.0.0/idna-tables-context" =>
        "iana.idna-tables-11.0.0.idna-tables-context",
      # MR is all-lowercase by convention, so the corpus' handful of camelCase
      # slugs are folded. Verified collision-free across all 3405 rows.
      "IANA clue/personType" => "iana.clue.persontype",
      "IANA ip-over-IEEE1394/ip-over-IEEE1394-1" =>
        "iana.ip-over-ieee1394.ip-over-ieee1394-1",
    }.each do |ref, mr|
      it "#{ref} renders #{mr}" do
        expect(parse(ref).to_mr_string).to eq(mr)
      end
    end
  end

  describe "non-empty" do
    it "produces a non-empty MR for a top registry" do
      expect(parse("IANA calipso").to_mr_string).not_to be_empty
    end

    it "produces a non-empty MR for a sub-registry" do
      expect(parse("IANA _6lowpan-parameters/lowpan_nhc").to_mr_string)
        .not_to be_empty
    end
  end

  describe "distinct identifiers never collide" do
    [
      ["IANA _6lowpan-parameters", "IANA _6lowpan-parameters/lowpan_nhc"],
      ["IANA _6lowpan-parameters/lowpan_nhc",
       "IANA _6lowpan-parameters/esc-extension-types"],
      ["IANA sip-parameters/sip-parameters-13",
       "IANA sip-parameters/sip-parameters-14"],
      ["IANA calipso", "IANA edhoc"],
      ["IANA idna-tables-6.2.0/idna-tables-context",
       "IANA idna-tables-11.0.0/idna-tables-context"],
    ].each do |a, b|
      it "#{a} and #{b} differ" do
        expect(parse(a).to_mr_string).not_to eq(parse(b).to_mr_string)
      end
    end
  end

  describe "filename safety" do
    # The documented MR charset is [a-z0-9.-] plus `_` (supplement separator).
    # IANA slugs legitimately contain `_`, so a slug is not re-parseable by
    # Pubid::Parsers::MrString — uniqueness and filename-safety are what this
    # buys, not MR round-tripping.
    %w[
      IANA\ calipso
      IANA\ _6lowpan-parameters/lowpan_nhc
      IANA\ smi-numbers/smi-numbers-1.3.6.1.2.1.198.4
      IANA\ clue/personType
      IANA\ openpgp/openpgp-hash-alg-ids-rsa-sig-emsa-pkcs1-v1_5-padding
    ].each do |ref|
      it "#{ref} stays inside [a-z0-9._-]" do
        expect(parse(ref).to_mr_string).to match(/\A[a-z0-9._-]+\z/)
      end
    end

    it "to_slug agrees with to_mr_string" do
      id = parse("IANA _6lowpan-parameters/lowpan_nhc")
      expect(id.to_slug).to eq(id.to_mr_string)
    end
  end
end
