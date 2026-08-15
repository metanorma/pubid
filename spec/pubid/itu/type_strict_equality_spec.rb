# frozen_string_literal: true

require "spec_helper"

# `Pubid::Itu::Identifier#==` is class-strict — `instance_of?(self.class)`,
# the rule `Supplement#==` already used: the ITU *type* is part of the
# identity, not just sector/series/number. This exists because Reports number
# independently of Recommendations — "ITU-R BT.2020-1" names two real,
# both-current documents — and `#matches?` is defined as
# `exclude(*ignore) == other.exclude(*ignore)`, so a loose `==` would let a
# lookup resolve one to the other.
#
# Because the guard is shared, it also settles three comparisons that used to be
# ASYMMETRIC (true one way, false the other, so the answer depended on argument
# order). They are pinned here so any future relaxation is a deliberate,
# visible decision.
RSpec.describe "Pubid::Itu type-strict equality" do
  def parse(str) = Pubid::Itu.parse(str)

  describe "a Report and a Recommendation of the same series/number" do
    let(:report) { parse("Report ITU-R BT.2020-1") }
    let(:recommendation) { parse("ITU-R BT.2020-1") }

    it "is unequal in both directions" do
      expect(report).not_to eq(recommendation)
      expect(recommendation).not_to eq(report)
    end

    it "is unequal under #matches? whichever side the reference is on" do
      expect(report.matches?(recommendation, ignore: %i[year])).to be false
      expect(recommendation.matches?(report, ignore: %i[year])).to be false
    end

    it "still narrows to the same relaton-index key" do
      # Relaton bsearches on root.number and then matches the full hash, so the
      # two share a bucket and are separated by `_type`.
      expect(report.root.number).to eq(recommendation.root.number)
      expect(report.to_hash["_type"]).not_to eq(recommendation.to_hash["_type"])
    end
  end

  # A joint recommendation is ONE document published under two designations, so
  # "ITU-T G.780" is a reasonable reference to "ITU-T G.780/Y.1351". Before the
  # class-strict guard, `recommendation == combined` was true but
  # `combined == recommendation` was false — order-dependent, so a caller could
  # not rely on it either way. It is now consistently false; a caller matching a
  # bare primary designation against a joint document must narrow on
  # `root.number` (which agrees) rather than on `==`.
  describe "a bare primary designation and its joint recommendation" do
    let(:bare) { parse("ITU-T G.780") }
    let(:joint) { parse("ITU-T G.780/Y.1351") }

    it "is unequal in both directions (was asymmetric before)" do
      expect(bare).not_to eq(joint)
      expect(joint).not_to eq(bare)
    end

    it "still shares the relaton-index narrowing key" do
      expect(bare.root.number).to eq(joint.root.number)
    end
  end

  describe "two identifiers of the same type" do
    it "still compares by value" do
      %w[ITU-R\ BT.2020-1 Report\ ITU-R\ BT.2020-1].each do |ref|
        one = parse(ref)
        other = parse(ref.dup)
        expect(one).to eq(other)
      end
    end

    it "survives a from_hash round-trip" do
      %w[ITU-R\ BT.2020-1 Report\ ITU-R\ BT.2020-1 ITU-T\ G.780/Y.1351
         ITU-R\ 23.HDB ITU\ OB\ No.\ 1283].each do |ref|
        id = parse(ref)
        expect(Pubid::Itu::Identifier.from_hash(id.to_hash)).to eq(id)
      end
    end
  end
end
