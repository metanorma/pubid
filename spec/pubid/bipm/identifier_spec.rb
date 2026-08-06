# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pubid::Bipm::Identifier do
  describe ".parse — committee documents" do
    context "short abbreviated key form" do
      subject { described_class.parse("CCTF REC 2 (2012)") }

      it "returns a CommitteeDocument with flat attributes" do
        expect(subject).to be_a(Pubid::Bipm::Identifiers::CommitteeDocument)
        expect(subject.group).to eq("CCTF")
        expect(subject.type_code).to eq("REC")
        expect(subject.number).to eq("2")
        expect(subject.year).to eq(2012)
        expect(subject.language).to be_nil
        expect(subject.form).to eq("short")
      end

      it "round-trips" do
        expect(subject.to_s).to eq("CCTF REC 2 (2012)")
      end
    end

    context "with a language suffix" do
      subject { described_class.parse("CCTF REC 2 (2012, E)") }

      it "captures the language and round-trips" do
        expect(subject.language).to eq("E")
        expect(subject.to_s).to eq("CCTF REC 2 (2012, E)")
      end
    end

    context "number-less declaration" do
      subject { described_class.parse("CGPM DECL (1889)") }

      it "leaves number nil and round-trips" do
        expect(subject.type_code).to eq("DECL")
        expect(subject.number).to be_nil
        expect(subject.to_s).to eq("CGPM DECL (1889)")
      end
    end

    context "hyphenated number" do
      subject { described_class.parse("JCRB ACT 10-1 (2003)") }

      it "preserves the hyphenated number" do
        expect(subject.number).to eq("10-1")
        expect(subject.to_s).to eq("JCRB ACT 10-1 (2003)")
      end
    end

    context "full English name (long form)" do
      subject { described_class.parse("CCL Recommendation 1 (2001)") }

      it "normalizes the type word to a code and marks form long" do
        expect(subject.type_code).to eq("REC")
        expect(subject.form).to eq("long")
        expect(subject.language).to eq("E")
        expect(subject.to_s).to eq("CCL Recommendation 1 (2001)")
      end
    end

    context "full French name (long form)" do
      subject { described_class.parse("Recommandation 1 du CCL (2001)") }

      it "captures group + code from the French word order" do
        expect(subject.group).to eq("CCL")
        expect(subject.type_code).to eq("REC")
        expect(subject.language).to eq("F")
        expect(subject.to_s).to eq("Recommandation 1 du CCL (2001)")
      end
    end

    context "French connective for the feminine CGPM" do
      subject { described_class.parse("Résolution 1 de la CGPM (1927)") }

      it "renders 'de la' for CGPM" do
        expect(subject.to_s).to eq("Résolution 1 de la CGPM (1927)")
      end
    end

    context "bare MRA-interpretation form (no type word)" do
      subject { described_class.parse("CIPM 2005-06") }

      it "parses as a type-less CommitteeDocument and round-trips" do
        expect(subject).to be_a(Pubid::Bipm::Identifiers::CommitteeDocument)
        expect(subject.group).to eq("CIPM")
        expect(subject.type_code).to be_nil
        expect(subject.number).to eq("2005-06")
        expect(subject.year).to be_nil
        expect(subject.to_s).to eq("CIPM 2005-06")
      end

      it "exposes a non-empty root.number for the relaton index" do
        expect(subject.root.number).to eq("2005-06")
      end

      it "round-trips through to_hash/from_hash" do
        hash = subject.to_hash
        expect(described_class.from_hash(hash).to_hash).to eq(hash)
      end

      it "builds a URN without raising" do
        expect(subject.to_urn.to_s).to eq("urn:bipm:cipm::2005-06")
      end

      it "carries an optional publication year when present" do
        dated = described_class.parse("CIPM 2005-06 (2005)")
        expect(dated.year).to eq(2005)
        expect(dated.to_s).to eq("CIPM 2005-06 (2005)")
      end
    end
  end

  describe ".parse — meetings" do
    it "parses English ordinal meetings and round-trips" do
      id = described_class.parse("CGPM 17th Meeting (1983)")
      expect(id).to be_a(Pubid::Bipm::Identifiers::Meeting)
      expect(id.number).to eq("17")
      expect(id.year).to eq(1983)
      expect(id.to_s).to eq("CGPM 17th Meeting (1983)")
    end

    it "reproduces the naive data ordinals (11st/12nd/13rd)" do
      %w[
        CCAUV\ 11st\ Meeting\ (2017)
        CCAUV\ 12nd\ Meeting\ (2019)
        CCAUV\ 13rd\ Meeting\ (2021)
      ].each do |ref|
        expect(described_class.parse(ref).to_s).to eq(ref)
      end
    end

    it "keeps the first component's ordinal for ranges" do
      id = described_class.parse("CIPM 100-1th Meeting (2011)")
      expect(id.number).to eq("100-1")
      expect(id.to_s).to eq("CIPM 100-1th Meeting (2011)")
    end

    it "parses the French réunion form" do
      id = described_class.parse("CCAUV 10<sup>e</sup> réunion (2015)")
      expect(id.language).to eq("F")
      expect(id.to_s).to eq("CCAUV 10<sup>e</sup> réunion (2015)")
    end
  end

  describe ".parse — Metrologia" do
    it "parses volume only" do
      id = described_class.parse("Metrologia 51")
      expect(id).to be_a(Pubid::Bipm::Identifiers::MetrologiaArticle)
      expect(id.volume).to eq(51)
      expect(id.issue).to be_nil
      expect(id.to_s).to eq("Metrologia 51")
    end

    it "parses volume + issue + (alphanumeric) article" do
      id = described_class.parse("Metrologia 55 1A 06007")
      expect(id.volume).to eq(55)
      expect(id.issue).to eq("1A")
      expect(id.article).to eq("06007")
      expect(id.to_s).to eq("Metrologia 55 1A 06007")
    end
  end

  describe ".parse — SI Brochure" do
    it "parses the English form" do
      id = described_class.parse("BIPM SI Brochure 9e v3.01 (2019/2024, E)")
      expect(id).to be_a(Pubid::Bipm::Identifiers::SiBrochure)
      expect(id.edition).to eq("9e")
      expect(id.version).to eq("v3.01")
      expect(id.years).to eq("2019/2024")
      expect(id.language).to eq("E")
      expect(id.to_s).to eq("BIPM SI Brochure 9e v3.01 (2019/2024, E)")
    end

    it "keeps 'sur le SI' for the French form" do
      ref = "BIPM SI Brochure sur le SI 9e v3.01 (2019/2024, F)"
      expect(described_class.parse(ref).to_s).to eq(ref)
    end
  end

  describe ".parse — JCGM exclusion" do
    it "does not parse JCGM (owned by Pubid::Jcgm)" do
      expect { described_class.parse("JCGM 24th Meeting (2021)") }
        .to raise_error(RuntimeError)
      expect { described_class.parse("JCGM 100:2008") }
        .to raise_error(RuntimeError)
    end
  end

  describe ".parse — input guard" do
    it "rejects an over-long input before parsing" do
      expect { Pubid::Bipm.parse("CCTF REC 2 (2012)#{'x' * 1000}") }
        .to raise_error(ArgumentError)
    end
  end
end
