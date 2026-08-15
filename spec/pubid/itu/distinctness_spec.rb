# frozen_string_literal: true

require "spec_helper"

# Every identity-bearing marker added for the unparseable-forms work must reach
# ALL THREE identity surfaces — `to_s`, `to_urn` and `to_mr_string` — not just
# `==`. A marker that only reaches `==` still lets two distinct documents share
# a URN or an output slug.
RSpec.describe "ITU identifier distinctness across rendering surfaces" do
  def parse(str) = Pubid::Itu.parse(str)

  # rubocop:disable Layout/LineLength
  PAIRS = {
    "qualifier vs none" => ["ITU-T D.200 R (10/1976)", "ITU-T D.200 (10/1976)"],
    "qualifier letters" => ["ITU-T Q.2931 B", "ITU-T Q.2931 C"],
    "spaced edition vs none" => ["ITU-T E.250 bis (12/1972)", "ITU-T E.250 (12/1972)"],
    "glued edition vs none" => ["ITU-T X.50bis", "ITU-T X.50"],
    "attachment vs none" => ["ITU-T H.350 attachment (08/2003)", "ITU-T H.350 (08/2003)"],
    "range vs lower bound" => ["ITU-T Q.120-Q.139 (11/1988)", "ITU-T Q.120 (11/1988)"],
    "series word, group" => ["ITU-T E-100 series Suppl. 2 (10/1984)", "ITU-T E-100 Suppl. 2 (10/1984)"],
    "series word, dotted code" => ["ITU-T E.1100 series Suppl. 1 (03/2012)", "ITU-T E.1100 Suppl. 1 (03/2012)"],
    "series groups" => ["ITU-T E-100 Suppl. 2 (10/1984)", "ITU-T E-300 Suppl. 2 (10/1984)"],
    "appendix material" => ["ITU-T G.726 App. II test vectors (03/1991)", "ITU-T G.726 App. II (03/1991)"],
    "appendix labels" => ["ITU-T G.113 App. I", "ITU-T G.113 App. II"],
    # Reports and Recommendations number independently, so these are two real,
    # both-current ITU documents that happen to share a series/number/edition.
    "report vs recommendation" => ["Report ITU-R BT.2020-1", "ITU-R BT.2020-1"],
    # A supplement slugs FLAT (no mr_supplement_suffix), from the sector/series/
    # code copied up from its base — so report-ness has to reach it explicitly.
    "report supplement" => ["Report ITU-R BT.2020-1 Suppl. 1",
                            "ITU-R BT.2020-1 Suppl. 1"],
    "report corrigendum" => ["Report ITU-R M.2134 (2008) Cor. 1 (10/2009)",
                             "ITU-R M.2134 (2008) Cor. 1 (10/2009)"],
    "report annex" => ["Report ITU-R BT.2020-1 Annex A", "ITU-R BT.2020-1 Annex A"],
  }.freeze

  # These differ only in their SUPPLEMENT TYPE, which the ITU URN convention
  # (and hence the URN generator and the MR slug) does not encode at all — so
  # they are checked for `to_s`/`==` distinctness only. See the pinned
  # pre-existing gap at the bottom of this file.
  SUPPLEMENT_TYPE_PAIRS = {
    "technical corrigendum" => ["ITU-T H.262 (1995) Technical Cor. 1", "ITU-T H.262 (1995) Cor. 1"],
    "addendum vs amendment" => ["ITU-T X.680 Add. 1", "ITU-T X.680 Amd. 1"],
  }.freeze
  # rubocop:enable Layout/LineLength

  SUPPLEMENT_TYPE_PAIRS.each do |label, (a, b)|
    context label do
      it "renders differently and compares unequal" do
        expect(parse(a).to_s).not_to eq(parse(b).to_s)
        expect(parse(a)).not_to eq(parse(b))
        expect(parse(b)).not_to eq(parse(a))
      end
    end
  end

  PAIRS.each do |label, (a, b)|
    context label do
      let(:one) { parse(a) }
      let(:two) { parse(b) }

      it "renders differently" do
        expect(one.to_s).not_to eq(two.to_s)
      end

      it "compares unequal, in both directions" do
        expect(one).not_to eq(two)
        expect(two).not_to eq(one)
      end

      it "gets a distinct URN" do
        expect(one.to_urn).not_to eq(two.to_urn)
      end

      it "gets a distinct MR string" do
        expect(one.to_mr_string).not_to eq(two.to_mr_string)
      end
    end
  end

  # A series-code document joins with a dash; rendering "EMC.5" in the URN
  # would be ambiguous with a hypothetical "ITU-T EMC.5".
  it "keeps the series-code dash in the URN" do
    expect(parse("ITU-T EMC-5 (2003)").to_urn).to eq("urn:itu:t:EMC-5:2003")
  end

  describe "the markers also survive on a combined identifier" do
    # with_series offers these slots on either side of combined_suffixes, so
    # the CombinedIdentifier branch must forward them too.
    {
      "ITU-T H.350/X.1 attachment (08/2003)" => "ITU-T H.350/X.1 (08/2003)",
      "ITU-T Q.120-Q.139/X.1 (11/1988)" => "ITU-T Q.120/X.1 (11/1988)",
    }.each do |with, without|
      it "distinguishes #{with}" do
        expect(parse(with).to_s).to eq(with)
        expect(parse(with)).not_to eq(parse(without))
      end
    end
  end

  # PRE-EXISTING GAP, deliberately not fixed here — pinned so it stays visible.
  #
  # The ITU URN convention encodes no supplement TYPE, so `generate_supplement_urn`
  # emits only "<base>:<ordinal>[:<date>]" and the MR slug likewise carries only
  # the base's sector/series/code. Amd. 1, Cor. 1, Err. 1 and Add. 1 of one base
  # therefore share both. This is true on `main` for Amd./Cor./Err. and is not
  # introduced by the Addendum and Technical-Corrigendum work — those simply
  # join the existing collision. `to_s`, `to_hash` and `==` all distinguish them
  # correctly, which is what relaton's index gate uses.
  #
  # Fixing it means adding a type segment to every ITU supplement URN, a
  # behaviour change well beyond this change's scope.
  describe "supplement types share a URN and MR slug" do
    let(:amendment)   { parse("ITU-T Z.100 (1999) Amd. 1") }
    let(:corrigendum) { parse("ITU-T Z.100 (1999) Cor. 1") }

    it "still collides on the URN" do
      expect(amendment.to_urn).to eq(corrigendum.to_urn)
    end

    it "still collides on the MR string" do
      expect(amendment.to_mr_string).to eq(corrigendum.to_mr_string)
    end

    it "but is distinguished by to_s, ==, and the serialized hash" do
      expect(amendment.to_s).not_to eq(corrigendum.to_s)
      expect(amendment).not_to eq(corrigendum)
      expect(amendment.to_hash).not_to eq(corrigendum.to_hash)
    end
  end

  # PRE-EXISTING GAP, likewise pinned rather than fixed.
  #
  # Builder#build_supplement copies sector/series/code down from the base so a
  # parsed supplement has a full MR slug, but those copies are deliberately NOT
  # serialized (they would duplicate the base — see supplement_sector_to_kv).
  # So a supplement rebuilt through from_hash has none of them and its MR slug
  # collapses to "itu.<date>", while `to_s`, `to_urn`, `to_hash` and `==` are
  # all symmetric. True on `main` for every based supplement; the new types
  # simply inherit it.
  #
  # The fix is to give Supplement an `mr_supplement_suffix` so the shared MR
  # renderer recurses into `base` (as AnnexOfRecommendation already does), which
  # would change every existing ITU supplement MR string.
  describe "a based supplement's MR slug is not from_hash-symmetric" do
    %w[
      ITU-T\ E.156\ Suppl.\ 2\ (10/1984)
      ITU-T\ Z.100\ (1999)\ Cor.\ 1\ (10/2001)
      ITU-T\ EMC-5\ (2003)\ Amd.\ 1\ (10/2009)
    ].each do |id|
      context id do
        let(:parsed)  { parse(id) }
        let(:rebuilt) { Pubid::Itu::Identifier.from_hash(parsed.to_hash) }

        it "loses the copied sector/series/code from the slug" do
          expect(parsed.to_mr_string).not_to eq(rebuilt.to_mr_string)
        end

        it "is symmetric on every other surface" do
          expect(rebuilt.to_s).to eq(parsed.to_s)
          expect(rebuilt.to_urn).to eq(parsed.to_urn)
          expect(rebuilt.to_hash).to eq(parsed.to_hash)
          expect(rebuilt).to eq(parsed)
        end
      end
    end
  end
end
