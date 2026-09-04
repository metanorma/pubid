# frozen_string_literal: true

require "rspec"
require_relative "../../../lib/pubid/jcgm"
require_relative "../../support/urn_round_trip"

RSpec.describe Pubid::Jcgm::UrnParser do
  it_behaves_like "flavor URN round-trip", Pubid::Jcgm, [
    "JCGM 200:2012",
    "JCGM 100:2008",
    "JCGM 17th Meeting (2012)",
    "JCGM 11st Meeting (2006)",
    "JCGM 11st Meeting",
    "JCGM GUM",
    "JCGM VIM-3",
    "JCGM GUM-6:2020",
    "JCGM 100:2008(E)",
    "JCGM 200:2012(E/F)",
    "JCGM 200:2008 Corrigendum",
    "JCGM 101:2008/Cor 1:2009",
    "JCGM 100:2008/Amd 1",
  ]

  # Every identifier is rebuilt from the URN segments, so a URN must read back
  # as the *same document* — not merely as something that renders. Flattening
  # the segments into a string used to lose the GUM prefix (a raise), the
  # language list and the whole supplement layer (silently).
  describe "reads a URN back as the same identifier" do
    [
      "JCGM 200:2008",
      "JCGM 100",
      "JCGM GUM",
      "JCGM VIM-3",
      "JCGM GUM-6:2020",
      "JCGM 100:2008(E)",
      "JCGM 200:2007(F)",
      "JCGM 200:2012(E/F)",
      "JCGM 200:2008 Corrigendum",
      "JCGM 101:2008/Cor 1:2009",
      "JCGM 100:2008/Cor 1",
      "JCGM 100:2008/Amd 1",
      "JCGM 17th Meeting (2012)",
      "JCGM 11st Meeting",
    ].each do |ref|
      it ref.inspect do
        id = Pubid::Jcgm.parse(ref)
        back = Pubid.parse(id.to_urn)

        expect(back).to eq(id)
        expect(back.to_s).to eq(ref)
        expect(back.class).to eq(id.class)
      end
    end
  end

  # A meeting URN is rebuilt straight from its segments rather than rendered
  # and re-parsed, so the segment handling the string round-trip used to give
  # for free is pinned here.
  describe "meeting URNs" do
    it "reconstructs an identifier equal to the parsed one" do
      expect(Pubid.parse("urn:jcgm:meeting:11:2006"))
        .to eq(Pubid::Jcgm.parse("JCGM 11st Meeting (2006)"))
    end

    it "reconstructs a dateless meeting equal to the parsed one" do
      expect(Pubid.parse("urn:jcgm:meeting:11"))
        .to eq(Pubid::Jcgm.parse("JCGM 11st Meeting"))
    end

    it "leaves the date nil when the year segment is absent" do
      expect(Pubid.parse("urn:jcgm:meeting:11").date).to be_nil
    end

    # `Identifiers::Meeting.ordinal` reads the number with `to_i`, so the
    # direct build normalizes the segment the same way.
    {
      "urn:jcgm:meeting:11:2006" => "JCGM 11st Meeting (2006)",
      "urn:jcgm:meeting:11" => "JCGM 11st Meeting",
      "urn:jcgm:meeting:011:2006" => "JCGM 11st Meeting (2006)",
      "urn:jcgm:meeting:abc:2006" => "JCGM 0th Meeting (2006)",
      "urn:jcgm:meeting" => "JCGM 0th Meeting",
    }.each do |urn, rendered|
      it "renders #{urn} as #{rendered.inspect}" do
        expect(Pubid.parse(urn).to_s).to eq(rendered)
      end
    end

    # Nothing re-parses the reconstructed string any more, so the year segment
    # is validated here instead — the grammar accepts only 19xx/20xx.
    ["urn:jcgm:meeting:11:abcd", "urn:jcgm:meeting:11:1899"].each do |urn|
      it "rejects #{urn}" do
        expect { Pubid.parse(urn) }
          .to raise_error(Pubid::UrnParser::Errors::ParseError, /Invalid year/)
      end
    end
  end

  describe "supplement URNs" do
    it "keeps the corrigendum instead of decaying to its base" do
      id = Pubid.parse("urn:jcgm:200:2008:corrigendum")

      expect(id).to be_a(Pubid::Jcgm::Identifiers::Corrigendum)
      expect(id.base.to_s).to eq("JCGM 200:2008")
      expect(id.number).to be_nil
      expect(id.to_s).to eq("JCGM 200:2008 Corrigendum")
    end

    it "restores a numbered corrigendum with its own date" do
      id = Pubid.parse("urn:jcgm:101:2008:corrigendum:1:2009")

      expect(id.number).to eq("1")
      expect(id.date.year).to eq("2009")
      expect(id.to_s).to eq("JCGM 101:2008/Cor 1:2009")
    end

    it "restores an amendment" do
      id = Pubid.parse("urn:jcgm:100:2008:amendment:1")

      expect(id).to be_a(Pubid::Jcgm::Identifiers::Amendment)
      expect(id.to_s).to eq("JCGM 100:2008/Amd 1")
    end
  end

  describe "GUM guide URNs" do
    it "reads the gum. prefix back as a GumGuide" do
      id = Pubid.parse("urn:jcgm:gum.6:2020")

      expect(id).to be_a(Pubid::Jcgm::Identifiers::GumGuide)
      expect(id.number).to eq("6")
      expect(id.to_s).to eq("JCGM GUM-6:2020")
    end

    # KNOWN GAP, on the generator side: a full date renders as its year alone,
    # so the month and day cannot be recovered from the URN.
    it "recovers only the year of a full date" do
      id = Pubid::Jcgm.parse("JCGM GUM-1:2022-11-28")

      expect(id.to_urn).to eq("urn:jcgm:gum.1:2022")
      expect(Pubid.parse(id.to_urn).to_s).to eq("JCGM GUM-1:2022")
    end
  end

  describe "language segments" do
    it "restores a single language" do
      expect(Pubid.parse("urn:jcgm:100:2008:en").to_s).to eq("JCGM 100:2008(E)")
    end

    it "restores a language pair" do
      expect(Pubid.parse("urn:jcgm:200:2012:en,fr").to_s)
        .to eq("JCGM 200:2012(E/F)")
    end
  end

  describe "malformed document URNs" do
    it "rejects a URN with no document number" do
      expect { Pubid.parse("urn:jcgm:") }
        .to raise_error(Pubid::UrnParser::Errors::ParseError,
                        /no document number/)
    end
  end
end
