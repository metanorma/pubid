# frozen_string_literal: true

require "spec_helper"

# IRE and NESC identifiers used to descend from bare Lutaml::Model::Serializable
# instead of Pubid::Ieee::Identifier — the same situation AIEE was in before it
# was reparented (see spec/pubid/ieee/aiee_roundtrip_spec.rb). Three
# consequences broke relaton's index-v2 gate, and all are *crashes on a
# successfully parsed id* rather than the safe "no identifier" failure mode:
#
#   1. `#root` was undefined      -> NoMethodError where relaton computes its
#                                    binary-search key `id.root.number.to_s`.
#   2. They were not assignable to AdoptedStandard#adopted_identifiers (declared
#      ::Pubid::Identifier)       -> Lutaml::Model::IncorrectModelError on
#                                    `to_hash` for the IRE-adopted forms
#                                    ("IEEE Std 159-1972 (52 IRE 7 S2)").
#   3. No polymorphic `_type`     -> `from_hash` could not route back.
#
# (issue #214 — "Stability of identifiers")

# Every IRE/NESC form found in the relaton-data-ieee corpus, the raw IEEE
# normtitle feed and the IEEE fixtures, with the rendering they produced
# *before* the reparenting. Rendering must be byte-identical afterwards.
IRE_NESC_RENDERINGS = {
  "52 IRE 7.S2" => "52 IRE 7.S2",
  "12 IRE 20.S2" => "12 IRE 20.S2",
  "C2-1997 National Electric Safety Code (NESC)" =>
      "C2-1997 National Electrical Safety Code",
  "National Electrical Safety Code, C2-2012" =>
      "C2-2012 National Electrical Safety Code",
  "2012 NESC Handbook, Seventh Edition" =>
      "IEEE Std 2012 NESC Handbook, Seventh Edition",
  "2017 National Electrical Safety Code(R) (NESC(R))" =>
      "IEEE Std 2017 National Electrical Safety Code(R) (NESC(R))",
  "2017 NESC(R) Handbook, Premier Edition" =>
      "IEEE Std 2017 NESC(R) Handbook, Premier Edition",
  "2017 NESC Redline" => "2017 NESC Redline",
  "Draft NESC, June 2011" =>
      "Draft National Electrical Safety Code, June 2011",
}.freeze

RSpec.describe "IEEE IRE/NESC identifier reparenting" do
  subject(:klass) { Pubid::Ieee::Identifier }

  IRE_NESC_RENDERINGS.each do |input, expected|
    context input.inspect do
      let(:id) { klass.parse(input) }

      it "is a Pubid::Ieee::Identifier" do
        expect(id).to be_a(Pubid::Ieee::Identifier)
      end

      it "renders unchanged" do
        expect(id.to_s).to eq(expected)
      end

      it "renders with the trademark symbol" do
        expect(id.to_s(trademark: true)).to eq("#{expected}™")
      end

      # relaton-index keys its binary search on `id.root.number.to_s`; a nil
      # number yields the empty key "" and silently defeats the search.
      it "is its own #root with a non-empty #number" do
        expect(id.root).to be(id)
        expect(id.root.number.to_s).not_to be_empty
      end

      it "carries a polymorphic _type" do
        expect(id.to_hash["_type"]).to start_with("pubid:ieee:")
      end

      it "round-trips through to_hash/from_hash" do
        hash = id.to_hash
        expect(klass.from_hash(hash).to_hash).to eq(hash)
      end

      it "renders identically after from_hash" do
        expect(klass.from_hash(id.to_hash).to_s).to eq(expected)
      end
    end
  end

  # Nesc::Base is abstract. An instance of it would serialize the derived
  # `_type` "pubid:ieee:base", which from_hash cannot resolve back to NESC (it
  # would silently degrade to a plain Pubid::Ieee::Identifier), and it carries
  # no CodeNumber `number`, so it would key the relaton index as "".
  describe "Nesc::Base" do
    it "cannot be instantiated directly" do
      expect { Pubid::Ieee::Identifiers::Nesc::Base.new }
        .to raise_error(NotImplementedError, /abstract/)
    end

    it "still constructs its concrete leaves" do
      expect(Pubid::Ieee::Identifiers::Nesc::Edition.new)
        .to be_a(Pubid::Ieee::Identifiers::Nesc::Base)
    end
  end

  # A year-less NESC id is reachable via `#exclude(:year)` (which `#matches?`
  # uses) and via from_hash of a partial row. It must render as a clean partial
  # reference — not with the dangling separator/double space a bare
  # interpolation would leave behind.
  describe "partial (year-less) NESC references" do
    {
      "C2-2012 National Electrical Safety Code" =>
        "C2 National Electrical Safety Code",
      "2012 NESC Handbook, Seventh Edition" =>
        "IEEE Std NESC Handbook, Seventh Edition",
      "2017 NESC Redline" => "NESC Redline",
      "2017 National Electrical Safety Code(R) (NESC(R))" =>
        "IEEE Std National Electrical Safety Code(R) (NESC(R))",
    }.each do |input, expected|
      it "renders #{input.inspect} without its year as #{expected.inspect}" do
        expect(klass.parse(input).exclude(:year).to_s).to eq(expected)
      end
    end

    it "matches every year (the point of the partial form)" do
      dated = klass.parse("C2-2012 National Electrical Safety Code")
      other = klass.parse("C2-1997 National Electric Safety Code (NESC)")
      expect(dated.matches?(other, ignore: [:year])).to be true
    end
  end

  # Pre-existing dispatcher gap, unrelated to the reparenting and out of scope
  # here: the spelled-out draft form never reaches the NESC sub-parser (the
  # generic IEEE grammar claims it first), so it builds a plain Standard.
  it "does not yet route the spelled-out draft form to Nesc::Draft" do
    id = klass.parse("Draft National Electrical Safety Code, January 2016")
    expect(id).to be_a(Pubid::Ieee::Identifiers::Standard)
  end

  # The IRE-adopted forms crashed in `to_hash` because an Ire::Identifier is not
  # assignable to AdoptedStandard#adopted_identifiers (typed ::Pubid::Identifier).
  describe "IRE identifiers nested in an adopted standard" do
    [
      "IEEE Std 159-1972 (52 IRE 7 S2)",
      "55 IRE 2.S1 (IEEE Std 147)",
    ].each do |input|
      context input.inspect do
        let(:id) { klass.parse(input) }

        it "serializes without raising" do
          expect { id.to_hash }.not_to raise_error
        end

        it "round-trips through to_hash/from_hash" do
          hash = id.to_hash
          expect(klass.from_hash(hash).to_hash).to eq(hash)
        end
      end
    end
  end
end
