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

  # IEC/IEEE copublished references keep an edition, a colon year or a
  # "- Redline" tail inside `number`/`parts` rather than in dedicated
  # attributes. The mark still belongs at the end of the code, not after the
  # descriptive text. Note the split point varies: "60802 Edition 1" lands in
  # `number` while "-16 Edition 2" lands in `parts`.
  {
    "IEC/IEEE 60076-16 Edition 2.0 2018-09" =>
      "IEC/IEEE 60076-16™ Edition 2.0 2018-09",
    "IEC/IEEE 60802 Edition 1.0 2026-06" =>
      "IEC/IEEE 60802™ Edition 1.0 2026-06",
    "IEC/IEEE 62582-2:2022 Edition 2.0 2022-11" =>
      "IEC/IEEE 62582-2™:2022 Edition 2.0 2022-11",
    "IEC/IEEE 60079-30-1:2025 - Redline" =>
      "IEC/IEEE 60079-30-1™:2025 - Redline",
    "IEC/IEEE 60780-323 Edition 1.0 2016-02 - Redline" =>
      "IEC/IEEE 60780-323™ Edition 1.0 2016-02 - Redline",
    # A publication year the builder could not peel (a tail follows it) stays
    # inside the code too; the mark still belongs before it.
    "IEC/IEEE 62395.1-2024 Redline" => "IEC/IEEE 62395.1™-2024 Redline",
    # no descriptive tail: the year is a real attribute, mark precedes it
    "IEC/IEEE 60076-57-129:2017" => "IEC/IEEE 60076-57-129™:2017",
    # ...and here the builder *did* peel it, so the code never contains it
    "IEC/IEEE 61588-2021" => "IEC/IEEE 61588™-2021",
    "IEC/IEEE 61692-6-2021" => "IEC/IEEE 61692-6™-2021",
    # a part that merely looks like a year (1202) is not a boundary
    "IEC/IEEE 60076.57-1202" => "IEC/IEEE 60076.57-1202™",
    # A leading stage word puts the first whitespace *before* the number, so
    # it must not end the code — the mark falls back to the end instead of
    # printing "IEC/IEEE FDIS™ 60079-30-2".
    "IEC/IEEE FDIS 60079-30-2" => "IEC/IEEE FDIS 60079-30-2™",
    "IEC/IEEE CD P62704-5 ED1" => "IEC/IEEE CD P62704-5™ ED1",
    "IEC/IEEE TS P61869-105 ED1" => "IEC/IEEE TS P61869-105™ ED1",
    # ...including a stage word that itself ends in a digit
    "IEC/IEEE CD2 P62704-5 ED1" => "IEC/IEEE CD2 P62704-5™ ED1",
    # A glued language marker ends the code; without that the mark would skip
    # past it and land inside the edition phrase.
    "IEC/IEEE 62704-1(E) Edition 1.0 2017-05" =>
      "IEC/IEEE 62704-1™(E) Edition 1.0 2017-05",
    # the amendment ordinal is not part of the base document's number
    "IEC/IEEE 80005-1:2019/AMD1:2022" => "IEC/IEEE 80005-1™:2019/AMD1:2022",
  }.each do |ref, trademarked|
    context "\"#{ref}\"" do
      subject(:id) { Pubid::Ieee::Identifier.parse(ref) }

      it "marks the end of the code, not the end of the string" do
        expect(id.to_s(trademark: true)).to eq(trademarked)
      end

      it "leaves plain to_s unchanged (default off)" do
        expect(id.to_s).to eq(ref)
      end
    end
  end

  # The `62271-37-082` rows have been rendered three different ways across this
  # work; the mark belongs on the *primary* designation, not on the trailing
  # "Revision of ..." relationship text (which is a separate document's number).
  # These forms do not round-trip to_s (the outer parentheses are dropped), so
  # they need their own expectation rather than the table's `to_s == ref` guard.
  #
  # The two rows share an expectation because the builder's
  # `content.split(" (")` swallows the trailing " - Redline" — so the redline
  # document and its base
  # collapse onto one `to_s` *and* one `to_hash`. That is a **pre-existing**
  # data loss of the kind the "Redline suffix — preserve, don't drop" work fixed
  # for plain standards, unrelated to where the mark sits; asserted here only to
  # record today's behaviour, not to endorse it.
  revision_of = "IEC/IEEE 62271-37-082:2012(E) " \
                "(Revision of IEEE Std C37.082-1982)"
  revision_of_rendered = [
    "IEC/IEEE 62271-37-082:2012(E) Revision of IEEE Std C37.082-1982",
    "IEC/IEEE 62271-37-082™:2012(E) Revision of IEEE Std C37.082-1982",
  ]

  {
    revision_of => revision_of_rendered,
    "#{revision_of} - Redline" => revision_of_rendered,
  }.each do |ref, (plain, trademarked)|
    context "\"#{ref}\"" do
      subject(:id) { Pubid::Ieee::Identifier.parse(ref) }

      it "marks the primary designation, not the revision reference" do
        expect(id.to_s(trademark: true)).to eq(trademarked)
      end

      it "leaves plain to_s unchanged (default off)" do
        expect(id.to_s).to eq(plain)
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
