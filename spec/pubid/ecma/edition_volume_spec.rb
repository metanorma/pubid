# frozen_string_literal: true

require "spec_helper"

# ECMA carries the edition and the volume in the printed identifier.
#
# `Relaton::Index::Type#add_or_update` keys on a BARE `id.to_s` and cannot pass
# render options, so the default rendering is what the index keys on. With the
# edition omitted, all 22 editions of ECMA-74 collapsed onto one key and 383 of
# the 804 published rows vanished silently. Hence `with_edition` and
# `with_volume` default to TRUE here — the inverse of pubid's usual opt-in.
RSpec.describe "Pubid::Ecma edition and volume" do
  describe "parsing the edition suffix" do
    it "parses an integer edition" do
      id = Pubid::Ecma::Identifier.parse("ECMA-269 ed3")
      expect(id.number).to eq("269")
      expect(id.edition).to eq("3")
      expect(id.volume).to be_nil
    end

    # Editions are not all integers: ECMA-402 ed5.1 is a real document.
    it "parses a dotted edition" do
      id = Pubid::Ecma::Identifier.parse("ECMA-402 ed5.1")
      expect(id.edition).to eq("5.1")
    end

    it "parses an edition on a technical report" do
      id = Pubid::Ecma::Identifier.parse("ECMA TR/18 ed2")
      expect(id).to be_a(Pubid::Ecma::Identifiers::TechnicalReport)
      expect(id.edition).to eq("2")
    end

    it "parses an edition on a memento" do
      id = Pubid::Ecma::Identifier.parse("ECMA MEM/1970 ed1")
      expect(id).to be_a(Pubid::Ecma::Identifiers::Memento)
      expect(id.edition).to eq("1")
    end

    it "parses an edition on a standard with a part" do
      id = Pubid::Ecma::Identifier.parse("ECMA-418-1 ed2")
      expect(id.number).to eq("418")
      expect(id.part).to eq("1")
      expect(id.edition).to eq("2")
    end
  end

  describe "parsing the volume suffix" do
    it "parses edition and volume together" do
      id = Pubid::Ecma::Identifier.parse("ECMA-269 ed3 vol2")
      expect(id.edition).to eq("3")
      expect(id.volume).to eq("2")
    end

    # The two suffixes are independent `.maybe`s.
    it "parses a volume without an edition" do
      id = Pubid::Ecma::Identifier.parse("ECMA TR/101 vol1")
      expect(id.edition).to be_nil
      expect(id.volume).to eq("1")
    end
  end

  # ECMA prints a hyphen but references are commonly written with a space.
  # This is a NORMALIZING parse, so it must never enter the byte-exact `pass`
  # fixtures — `fixtures_spec.rb` asserts `parse(line).to_s == line`.
  describe "the space form" do
    it "accepts a space in place of the hyphen" do
      id = Pubid::Ecma::Identifier.parse("ECMA 6")
      expect(id).to be_a(Pubid::Ecma::Identifiers::Standard)
      expect(id.number).to eq("6")
    end

    it "normalises the space form back to the hyphen" do
      expect(Pubid::Ecma::Identifier.parse("ECMA 6").to_s).to eq("ECMA-6")
    end

    it "carries the suffixes on the space form too" do
      id = Pubid::Ecma::Identifier.parse("ECMA 269 ed3 vol2")
      expect(id.to_s).to eq("ECMA-269 ed3 vol2")
    end
  end

  describe "rendering" do
    subject(:id) { Pubid::Ecma::Identifier.parse("ECMA-269 ed3 vol2") }

    it "renders both suffixes by default" do
      expect(id.to_s).to eq("ECMA-269 ed3 vol2")
    end

    it "drops the edition on request" do
      expect(id.to_s(with_edition: false)).to eq("ECMA-269 vol2")
    end

    it "drops the volume on request" do
      expect(id.to_s(with_volume: false)).to eq("ECMA-269 ed3")
    end

    it "renders the bare document form with both dropped" do
      expect(id.to_s(with_edition: false, with_volume: false))
        .to eq("ECMA-269")
    end

    it "composes with with_publisher: false" do
      expect(id.to_s(with_publisher: false)).to eq("-269 ed3 vol2")
    end

    it "renders a dotted edition verbatim" do
      expect(Pubid::Ecma::Identifier.parse("ECMA-402 ed5.1").to_s)
        .to eq("ECMA-402 ed5.1")
    end

    it "renders the suffixes on a technical report" do
      expect(Pubid::Ecma::Identifier.parse("ECMA TR/18 ed2").to_s)
        .to eq("ECMA TR/18 ed2")
    end
  end

  # The suffix order is canonical, and a suffix marker without its number is a
  # parse failure rather than a silently ignored tail.
  describe "rejections" do
    [
      "ECMA-6 ed",
      "ECMA-402 ed5.",
      "ECMA-6 vol1 ed3",
      "ECMA ed3",
      "ECMA-6 edge",
      "ECMA-6 vol",
      "ECMA-6 ed3vol2",
    ].each do |input|
      it "rejects #{input.inspect}" do
        expect { Pubid::Ecma::Identifier.parse(input) }
          .to raise_error(RuntimeError, /Failed to parse/)
      end
    end
  end

  # `#matches?` is `exclude(*ignore) == other.exclude(*ignore)`, so a bare
  # reference must match every edition of the document once the edition is
  # excluded. This is what lets relaton resolve "ECMA-269" to a collection.
  describe "partial-reference matching" do
    let(:bare) { Pubid::Ecma::Identifier.parse("ECMA-269") }
    let(:third_edition) { Pubid::Ecma::Identifier.parse("ECMA-269 ed3") }
    let(:fourth_edition) { Pubid::Ecma::Identifier.parse("ECMA-269 ed4") }
    let(:second_volume) do
      Pubid::Ecma::Identifier.parse("ECMA-269 ed3 vol2")
    end

    it "distinguishes two editions" do
      expect(third_edition).not_to eq(fourth_edition)
    end

    it "distinguishes two volumes of one edition" do
      expect(second_volume).not_to eq(third_edition)
    end

    it "matches every edition when the edition is ignored" do
      expect(bare.matches?(third_edition, ignore: %i[edition volume]))
        .to be true
      expect(bare.matches?(fourth_edition, ignore: %i[edition volume]))
        .to be true
    end

    it "matches every volume when the volume is ignored" do
      expect(third_edition.matches?(second_volume, ignore: [:volume]))
        .to be true
    end
  end
end
