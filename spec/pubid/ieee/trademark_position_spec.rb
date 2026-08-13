# frozen_string_literal: true

require "spec_helper"

# IEEE attaches the trademark mark to the standard *number*, before the year
# and every suffix — "IEEE Std 1619™-2007", "IEEE Std 802.3®-2018" — not to
# the end of the fully rendered string. See metanorma/pubid#322.
#
# The registered mark (®) belongs to the 802 / 8802 / 2030 series whatever the
# publisher prefix or the project "P".
RSpec.describe "IEEE trademark position" do
  # reference => trademarked rendering
  {
    # plain standards
    "IEEE Std 1619-2007" => "IEEE Std 1619™-2007",
    "IEEE Std 528-2019" => "IEEE Std 528™-2019",
    "IEEE Std 1003.1-2017" => "IEEE Std 1003.1™-2017",
    "IEEE Std C37.09-2018" => "IEEE Std C37.09™-2018",
    # registered series, including the ISO/IEC 8802 and ANSI/IEEE forms
    "IEEE Std 802.3-2018" => "IEEE Std 802.3®-2018",
    "IEEE Std 802.1AB-2016" => "IEEE Std 802.1AB®-2016",
    "IEEE Std 2030.5-2018" => "IEEE Std 2030.5®-2018",
    "ANSI/IEEE 802.9a-1995" => "ANSI/IEEE 802.9a®-1995",
    # mark precedes the supplement suffixes
    "IEEE Std 802.16-2004/Cor 1-2005" =>
      "IEEE Std 802.16®-2004/Cor. 1-2005",
    "IEEE Std 1619-2007/Amd 1-2010" =>
      "IEEE Std 1619™-2007/Amd 1-2010",
    "ISO/IEC/IEEE 8802.3/Amd 7-2017" =>
      "ISO/IEC/IEEE 8802.3®/Amd 7-2017",
    # mark precedes the draft and the redline suffix
    "IEEE P802.1AE/D1.0" => "IEEE P802.1AE®/D1.0",
    "IEEE Std 802.16-2012 Redline" =>
      "IEEE Std 802.16®-2012 - Redline",
    # co-published and joint-development leaves
    "IEC/IEEE 60076-2016" => "IEC/IEEE 60076™-2016",
    "IEEE/ASTM SI 10-2010" => "IEEE/ASTM SI 10™-2010",
    "ISO/IEC/IEEE P26511/D8-2018" => "ISO/IEC/IEEE P26511™/D8-2018",
    # AIEE renders publisher + type + code then a date suffix, same shape
    "AIEE No 13-1930" => "AIEE No 13™-1930",
    # each co-equal designation carries its own mark
    "ANSI C37.61-1973 and IEEE Std 321-1973" =>
      "ANSI C37.61™-1973 and IEEE Std 321™-1973",
    # the adopted child is a foreign identifier and stays unmarked
    "IEEE Std 144-1971 (ANSI C37.24-1971)" =>
      "IEEE Std 144™-1971 (ANSI C37.24-1971)",
  }.each do |ref, trademarked|
    context "\"#{ref}\"" do
      subject(:id) { Pubid::Ieee::Identifier.parse(ref) }

      it "renders the mark after the number, before every suffix" do
        expect(id.to_s(trademark: true)).to eq(trademarked)
      end

      it "leaves plain to_s unchanged (default off)" do
        expect(id.to_s).to eq(trademarked.delete("™®"))
      end
    end
  end

  # These leaves render a document *name* (or end with their code), so the
  # trailing mark already sits at the code boundary — position is unchanged.
  {
    "12 IRE 20.S2" => "12 IRE 20.S2™",
    "2012 NESC Handbook" => "IEEE Std 2012 NESC Handbook™",
  }.each do |ref, trademarked|
    it "keeps the trailing mark for #{ref}" do
      expect(Pubid::Ieee::Identifier.parse(ref).to_s(trademark: true))
        .to eq(trademarked)
    end
  end

  # Nesc::Standard *does* render a code first, so it follows the general rule.
  it "marks the NESC code, before the year" do
    id = Pubid::Ieee::Identifier.parse("National Electrical Safety Code, C2-2012")
    expect(id.to_s).to eq("C2-2012 National Electrical Safety Code")
    expect(id.to_s(trademark: true))
      .to eq("C2™-2012 National Electrical Safety Code")
  end

  # The ® series belongs to IEEE. AIEE dissolved in 1963, two decades before
  # the IEEE 802 series existed, so its own 802 must not claim the mark.
  it "does not claim the IEEE registered mark for a non-IEEE publisher" do
    id = Pubid::Ieee::Identifier.parse("AIEE Std No. 802")
    expect(id.to_s(trademark: true)).to eq("AIEE Std No. 802™")
  end

  it "honours JointDevelopment's ISO format" do
    id = Pubid::Ieee::Identifier.parse("ISO/IEC/IEEE P26511/D8-2018")
    expect(id.to_s(format: :iso, trademark: true))
      .to eq("ISO/IEC/IEEE 26511™:2018")
  end

  describe "Pubid::Ieee.trademark_symbol_for" do
    {
      ["802", nil] => "®",
      ["P802", nil] => "®",
      ["8802", nil] => "®",
      ["2030", nil] => "®",
      ["C63", nil] => "™",
      ["1619", nil] => "™",
      # a lettered series that merely starts with the same digits
      ["802", "C"] => "™",
      [nil, nil] => "™",
    }.each do |(number, prefix), symbol|
      it "returns #{symbol} for #{number.inspect}/#{prefix.inspect}" do
        expect(Pubid::Ieee.trademark_symbol_for(number, prefix)).to eq(symbol)
      end
    end

    # The publisher gate: the ® series is IEEE's.
    {
      ["802", ["IEEE"]] => "®",
      ["802", %w[ANSI IEEE]] => "®",
      ["802", ["ISO/IEC/IEEE"]] => "®",
      ["802", ["AIEE"]] => "™",
      ["2030", ["ASTM"]] => "™",
      # the ISO adoption of IEEE 802 is identified by its number alone
      ["8802", %w[ISO IEC]] => "®",
    }.each do |(number, publishers), symbol|
      it "returns #{symbol} for #{number} published by #{publishers.join('/')}" do
        expect(Pubid::Ieee.trademark_symbol_for(number, nil,
                                                publishers: publishers))
          .to eq(symbol)
      end
    end
  end

  # The mark must be purely additive: stripping it from the trademarked
  # rendering must give back the plain rendering, for every fixture. (Count is
  # ">= 1", not "== 1": a dual/multi-numbered id marks each co-equal
  # designation, as IEEE prints them.)
  describe "over the IEEE fixture corpus" do
    let(:references) do
      Dir[File.join(__dir__, "..", "..", "fixtures", "ieee", "**", "pass",
                    "*.txt")].flat_map do |file|
        File.read(file).split("\n").map(&:strip).reject do |line|
          line.empty? || line.start_with?("#")
        end
      end.map { |line| fixture_input(line) }
    end

    # A fixture line is either a bare round-tripping identifier or
    # "!<input>!<rendered>". Split on the LAST "!", because an input may itself
    # contain one ("!!IEEE 1070-1995!IEEE Std 1070-1995"). Feeding the raw line
    # to .parse would fail and be silently skipped — that quietly dropped 4,507
    # of the 8,653 rows from this guard.
    def fixture_input(line)
      return line unless line.start_with?("!")

      line.rpartition("!").first.delete_prefix("!")
    end

    it "finds fixtures to check" do
      expect(references).not_to be_empty
    end

    it "only ever adds a mark to the plain rendering" do
      checked = 0

      offenders = references.filter_map do |reference|
        id = begin
          Pubid::Ieee::Identifier.parse(reference)
        rescue StandardError
          next
        end

        plain = begin
          id.to_s
        rescue StandardError
          next
        end
        marked = id.to_s(trademark: true)
        checked += 1

        # The mark must be purely additive...
        additive = marked.delete("™®") == plain
        # ...and present — but only where there is something to mark. One
        # malformed fixture input ("IEEE Std 1299/C62.22.1-1 996") parses to a
        # MultiNumberedIdentifier with a nil primary_identifier and renders "";
        # that is pre-existing (the old code appended a bare "™" to it).
        present = plain.empty? || marked.count("™®") >= 1
        next if additive && present

        [reference, plain, marked]
      end

      expect(offenders).to eq([])
      # Floor guard — without it this example passes vacuously if the fixture
      # glob stops matching or every reference stops parsing.
      expect(checked).to be > 8_000
    end
  end
end
