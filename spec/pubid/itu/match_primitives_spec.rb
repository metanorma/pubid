# frozen_string_literal: true

require "spec_helper"

# Regression + behaviour spec for #289: ITU's identifier initializer is
# keyword-only (`initialize(**kwargs)`), so the shared `#exclude` — which
# rebuilds via `self.class.new(...)` — used to raise `ArgumentError` for every
# ITU id, making `#matches?(ignore:)` unusable. Beyond the crash, ITU keeps the
# edition ("-3") inside its `code.parts` component (like ETSI), so excluding
# `:part`/`:parts` must clear that nested component for a part-less reference to
# match all editions.
RSpec.describe "ITU match primitives" do
  describe "#exclude / #matches? no longer raise (regression for #289)" do
    it "does not raise on a bare self-match" do
      id = Pubid::Itu.parse("ITU-R P.838")
      expect { id.matches?(id) }.not_to raise_error
      expect(id.matches?(id)).to be true
    end

    it "does not raise on exclude" do
      id = Pubid::Itu.parse("ITU-R P.838-3")
      expect { id.exclude(:date) }.not_to raise_error
      expect { id.exclude(:parts) }.not_to raise_error
    end
  end

  describe "#exclude(:parts)" do
    subject(:excluded) { Pubid::Itu.parse("ITU-R P.838-3").exclude(:parts) }

    it "clears the part but keeps the series/number" do
      expect(excluded.code.parts).to eq([])
      expect(excluded.code.number).to eq("838")
      expect(excluded.series.to_s).to eq("P")
      expect(excluded.to_s).to eq("ITU-R P.838")
    end

    it "accepts :part as an alias" do
      also = Pubid::Itu.parse("ITU-R P.838-3").exclude(:part)
      expect(also.code.parts).to eq([])
      expect(also.to_s).to eq("ITU-R P.838")
    end

    it "leaves a part-less identifier unchanged" do
      base = Pubid::Itu.parse("ITU-R P.838")
      expect(base.exclude(:parts).to_s).to eq("ITU-R P.838")
    end
  end

  describe "#matches? ignoring the part" do
    it "matches a part-less reference against any edition" do
      partless = Pubid::Itu.parse("ITU-R P.838")
      edition3 = Pubid::Itu.parse("ITU-R P.838-3")
      expect(partless.matches?(edition3, ignore: [:parts])).to be true
    end

    it "matches two different editions of the same recommendation" do
      ed1 = Pubid::Itu.parse("ITU-R P.838-1")
      ed2 = Pubid::Itu.parse("ITU-R P.838-2")
      expect(ed1.matches?(ed2, ignore: [:parts])).to be true
    end

    it "still distinguishes different recommendations" do
      p838 = Pubid::Itu.parse("ITU-R P.838")
      p530 = Pubid::Itu.parse("ITU-R P.530")
      expect(p838.matches?(p530, ignore: [:parts])).to be false
    end

    it "does not match different editions when the part is NOT ignored" do
      ed1 = Pubid::Itu.parse("ITU-R P.838-1")
      ed2 = Pubid::Itu.parse("ITU-R P.838-2")
      expect(ed1.matches?(ed2)).to be false
    end
  end
end
