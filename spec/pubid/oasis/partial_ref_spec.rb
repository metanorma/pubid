# frozen_string_literal: true

require "spec_helper"

# Partial-reference matching for OASIS.
#
# #matches? is `exclude(*ignore) == other.exclude(*ignore)`, and OASIS keeps
# the whole printed slug verbatim in `original`. So `original` spells out the
# very component the caller is trying to ignore, and it survived the exclusion:
# a bare "OASIS WSDM" could never match "OASIS WSDM-v1.1" however much was
# ignored, which left relaton narrowing to the right index bucket and then
# matching nothing in it.
#
# Identifier#exclude therefore clears `original` — but ONLY when the exclusion
# touches the decomposition, the "reset the whole cluster" rule CSA applies to
# its year-format siblings. A plain == still compares `original`.
RSpec.describe "Pubid::Oasis partial reference matching" do
  def parse(ref)
    Pubid::Oasis.parse(ref)
  end

  describe "#matches?" do
    it "matches a bare reference against a versioned one" do
      expect(parse("OASIS WSDM"))
        .to be_matches(parse("OASIS WSDM-v1.1"), ignore: [:version])
    end

    it "matches a bare reference against a versioned, staged one" do
      expect(parse("OASIS OSLC-AM"))
        .to be_matches(parse("OASIS OSLC-AM-3.0-PS01"),
                       ignore: %i[version stage])
    end

    it "matches every version of one specification once version is ignored" do
      bare = parse("OASIS OSLC-CM")
      %w[
        OASIS\ OSLC-CM-3.0
        OASIS\ OSLC-CM-2.0
      ].each do |ref|
        expect(bare).to be_matches(parse(ref), ignore: [:version])
      end
    end

    it "ignores the specification name itself when asked" do
      a = parse("OASIS WSDM-v1.1")
      b = parse("OASIS STIX-v1.1")
      expect(a).to be_matches(b, ignore: [:number])
    end

    it "does not match a different specification" do
      expect(parse("OASIS WSDM"))
        .not_to be_matches(parse("OASIS STIX-v1.1"), ignore: [:version])
    end

    it "does not match a different part once only the version is ignored" do
      expect(parse("OASIS amqp-core-overview-v1.0-Pt0"))
        .not_to be_matches(parse("OASIS amqp-core-overview-v2.0-Pt1"),
                           ignore: [:version])
    end
  end

  describe "#exclude" do
    it "clears `original` when a decomposition key is excluded" do
      excluded = parse("OASIS WSDM-v1.1").exclude(:version)
      expect(excluded.original).to be_nil
      expect(excluded.number).to eq("WSDM")
      expect(excluded.version).to be_nil
    end

    it "leaves `original` alone when nothing in the cluster is excluded" do
      excluded = parse("OASIS WSDM-v1.1").exclude(:date)
      expect(excluded.original).to eq("WSDM-v1.1")
    end
  end

  # The reason `original` stays in a plain ==: decomposition loses fragment
  # order and drops repeated fragments, so it is not by itself an identity.
  describe "a plain == stays exact" do
    it "keeps two slugs with one decomposition distinct" do
      expect(parse("OASIS x-1.0-os-Pt1")).not_to eq(parse("OASIS x-1.0-Pt1-os"))
    end

    it "keeps a bare reference distinct from a versioned one" do
      expect(parse("OASIS WSDM")).not_to eq(parse("OASIS WSDM-v1.1"))
    end

    it "still round-trips through from_hash" do
      id = parse("OASIS OSLC-CoreShapes-3.0-PS01-Pt8")
      expect(Pubid::Oasis::Identifier.from_hash(id.to_hash)).to eq(id)
    end
  end
end
