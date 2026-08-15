# frozen_string_literal: true

require "spec_helper"

# Two shapes that both put a dash between letters and digits at the series
# position, and must never be confused:
#
#   * a series GROUP  — "E-100", "G-100" — one letter, a range of
#     Recommendations, only ever the subject of a Supplement;
#   * a series-CODE document — "EMC-5", "SEC-QKD" — two or more letters, a
#     document in its own right that can carry an Amd./Cor./Err.
RSpec.describe "ITU series groups and series-code documents" do
  def parse(str) = Pubid::Itu.parse(str)

  def round_trips?(str)
    parsed = parse(str)
    parsed.to_s == str &&
      Pubid::Itu::Identifier.from_hash(parsed.to_hash).to_hash == parsed.to_hash
  end

  describe "supplement of a series group" do
    context "ITU-T E-100 Suppl. 2 (10/1984)" do
      subject { "ITU-T E-100 Suppl. 2 (10/1984)" }

      let(:parsed) { parse(subject) }

      it "parses as a base-less Supplement of the group" do
        expect(parsed).to be_a(Pubid::Itu::Identifiers::Supplement)
        expect(parsed.base).to be_nil
        expect(parsed.series.series).to eq("E-100")
        expect(parsed.number).to eq("2")
      end

      it "round-trips" do
        expect(round_trips?(subject)).to be true
      end

      it "is distinct from the same ordinal in the plain E series" do
        expect(parsed).not_to eq(parse("ITU-T E Suppl. 2 (10/1984)"))
      end

      it "is distinct from another group's same ordinal" do
        expect(parsed).not_to eq(parse("ITU-T E-300 Suppl. 2 (10/1984)"))
      end
    end

    [
      "ITU-T E-300 Suppl. 1 (11/1980)",
      "ITU-T E-500 Suppl. 4 (10/1976)",
      "ITU-T E100-300 Suppl. 3 (10/1984)",
      "ITU-T Q-100 Suppl. 2 (11/1980)",
    ].each do |id|
      it "parses and round-trips #{id}" do
        expect(round_trips?(id)).to be true
      end
    end
  end

  describe "the literal 'series' word" do
    context "ITU-T E-300 series Suppl. 1 (11/1988)" do
      subject { "ITU-T E-300 series Suppl. 1 (11/1988)" }

      let(:parsed) { parse(subject) }

      it "keeps the word out of the series token" do
        expect(parsed.series.series).to eq("E-300")
        expect(parsed.series_word).to be true
      end

      it "round-trips" do
        expect(round_trips?(subject)).to be true
      end

      # These are genuinely different records in relaton-data-itu.
      it "is distinct from the same group without the word" do
        expect(parsed).not_to eq(parse("ITU-T E-300 Suppl. 1 (11/1988)"))
      end
    end

    # The word also follows a DOTTED code, which is why it cannot be folded
    # into the series token.
    context "ITU-T E.1100 series Suppl. 1 (03/2012)" do
      subject { "ITU-T E.1100 series Suppl. 1 (03/2012)" }

      let(:parsed) { parse(subject) }

      it "carries the word on the base recommendation" do
        expect(parsed.base.series.series).to eq("E")
        expect(parsed.base.code.number).to eq("1100")
        expect(parsed.base.series_word).to be true
      end

      it "round-trips" do
        expect(round_trips?(subject)).to be true
      end

      it "is distinct from the Recommendation itself" do
        expect(parse("ITU-T E.1100 series")).not_to eq(parse("ITU-T E.1100"))
      end
    end

    [
      "ITU-T E-800 series Suppl. 10 (01/2016)",
      "ITU-T G-100 series Suppl. 29 (03/1993)",
      "ITU-T Q-500 series Suppl. 1 (11/1988)",
      "ITU-T E-400 series Suppl. 8 (10/1984)",
    ].each do |id|
      it "parses and round-trips #{id}" do
        expect(round_trips?(id)).to be true
      end
    end
  end

  describe "series-code documents" do
    context "ITU-T EMC-5 (2003) Amd. 1 (10/2009)" do
      subject { "ITU-T EMC-5 (2003) Amd. 1 (10/2009)" }

      let(:parsed) { parse(subject) }

      it "is an Amendment of a series-code base" do
        expect(parsed).to be_a(Pubid::Itu::Identifiers::Amendment)
        expect(parsed.base.series.series).to eq("EMC")
        expect(parsed.base.code.number).to eq("5")
        expect(parsed.base.series_dash).to be true
      end

      it "round-trips" do
        expect(round_trips?(subject)).to be true
      end

      # The whole point of splitting series from number rather than storing
      # "EMC-5" in the series: relaton-index bsearches on root.number.
      it "exposes a non-empty root.number" do
        expect(parsed.root.number.to_s).to eq("5")
      end
    end

    {
      "ITU-T MES-2 (1992) Amd. 1 (01/1999)" => "2",
      "ITU-T QOS-2 (2011) Err. 1 (07/2012)" => "2",
      "ITU-T IMPL-8 (2010) Err. 1 (12/2011)" => "8",
      "ITU-T SEC-QKD (2020) Cor. 1 (04/2021)" => "QKD",
      "ITU-T EMC-3 (1974) Amd. 2 (01/1995)" => "3",
    }.each do |id, number|
      it "parses #{id} with root.number #{number}" do
        parsed = parse(id)
        expect(round_trips?(id)).to be true
        expect(parsed.root.number.to_s).to eq(number)
      end
    end

    it "distinguishes documents within one mnemonic series" do
      expect(parse("ITU-T EMC-3 (1974)")).not_to eq(parse("ITU-T EMC-5 (1974)"))
    end
  end

  # The one-letter/two-letter split is a corpus regularity, not an ITU rule.
  # Lock both sides so a future change to either rule is visible.
  describe "the group/document boundary" do
    {
      "ITU-T E-100 Suppl. 2" => ["E-100", nil],
      "ITU-T G-100 series Suppl. 1" => ["G-100", nil],
      "ITU-T Q-500 series Suppl. 1" => ["Q-500", nil],
    }.each do |id, (series, _)|
      it "treats #{id} as a series group" do
        parsed = parse(id)
        expect(parsed.series.series).to eq(series)
        expect(parsed.code).to be_nil
        expect(parsed.series_dash).to be false
      end
    end

    {
      "ITU-T EMC-5 (2003)" => %w[EMC 5],
      "ITU-T MES-2 (1992)" => %w[MES 2],
      "ITU-T SEC-QKD (2020)" => %w[SEC QKD],
    }.each do |id, (series, number)|
      it "treats #{id} as a series-code document" do
        parsed = parse(id)
        expect(parsed.series.series).to eq(series)
        expect(parsed.code.number).to eq(number)
        expect(parsed.series_dash).to be true
      end
    end
  end

  describe "the Operational Bulletin is not reachable through series_code_body" do
    # Without the OB guard on series_code_body this reached Builder#build's
    # Recommendation fallback, whose validate_ob_no_sector! raised an
    # ArgumentError that escapes Identifier.parse's ParseFailed rescue — a
    # rejected input became a crash for callers.
    ["ITU-T OB-1", "ITU-R OB-1"].each do |id|
      it "rejects #{id} with the documented parse error" do
        expect { parse(id) }
          .to raise_error(RuntimeError, /Failed to parse ITU identifier/)
      end
    end
  end

  describe "existing forms are unchanged" do
    it "still normalises the legacy Operational Bulletin spelling" do
      expect(parse("ITU-T OB.1096").to_s).to eq("ITU OB No. 1096")
    end

    [
      "ITU OB No. 1283",
      "ITU-T H Suppl. 1",
      "ITU-T E Suppl. 2 (10/1984)",
      "ITU-T G.711 (11/1988)",
    ].each do |id|
      it "still round-trips #{id}" do
        expect(round_trips?(id)).to be true
      end
    end

    it "does not serialize the flags for an ordinary recommendation" do
      hash = parse("ITU-T G.711 (11/1988)").to_hash

      expect(hash).not_to have_key("series_word")
      expect(hash).not_to have_key("series_dash")
    end
  end
end
