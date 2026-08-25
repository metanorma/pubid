# frozen_string_literal: true

require "spec_helper"

# The relaton-index contract for BIPM, plus the determinism tripwire for the
# `number` attribute.
#
# IMPORTANT: this file is only meaningful under the FULL suite
# (`bundle exec rake`), never `rspec spec/pubid/bipm` alone. BIPM declares
# `number` as a plain `:string` on the SHARED base Pubid::Bipm::Identifier
# (the IHO/JIS/GOST pattern), overriding the parent ::Pubid::Identifier's
# `attribute :number, Components::Code`. CLAUDE.md records that doing that on a
# class the concrete types INHERIT from can resolve against the parent
# definition nondeterministically under multi-flavor load — the IEEE/IETF
# lesson: passes flavor-only, flips `root.number` to "" under the full suite.
# BIPM predates that lesson and keeps every family attribute flat on the base,
# so these examples are the tripwire that catches a flip.
#
# Why it matters: Relaton::Index narrows search candidates by
# `Type#get_id_number` -> `id.number.to_s` with bsearch_left/bsearch_right.
# Before this change four of the six BIPM families never populated `number` at
# all, so 6,213 of the 7,922 published relaton-data-bipm index-v2 rows (78%)
# shared the empty key "" and the binary search degenerated to a linear scan —
# silently, with no error.
#
# The key is deliberately the COARSE, clustering one (a document and its
# variants share a bucket), matching the IETF draft-slug and IANA registry-slug
# precedents: a Metrologia article keys on its volume, and the short and full
# print spellings of a MEP or a Guide key alike. Per-article/per-document
# distinctness is delivered by the MR string, not by `number`.
module BipmIndexKeySpec
  # Every family, with the awkward corners of the real corpus: hyphenated
  # committee ordinals, the bare CIPM MRA form, meeting ranges, an alphanumeric
  # Metrologia issue, the SI Brochure variants, both MEP spellings.
  KEYS = {
    # CommitteeDocument
    "CCTF REC 2 (2012)" => "2",
    "CCTF REC 2 (2012, F)" => "2",
    "JCRB ACT 10-1 (2003)" => "10-1",
    "CGPM RES 1 (1927)" => "1",
    "Résolution 1 de la CGPM (1927)" => "1",
    "CIPM 2005-06" => "2005-06",
    # Meeting
    "CGPM 17th Meeting (1983)" => "17",
    "CIPM 100-1th Meeting (2011)" => "100-1",
    "CCAUV 10<sup>e</sup> réunion (2015)" => "10",
    # MetrologiaArticle — the volume, so every article of a volume clusters
    "Metrologia 1" => "1",
    "Metrologia 1 1" => "1",
    "Metrologia 51 1 128" => "51",
    "Metrologia 42 3 S138" => "42",
    "Metrologia 55 1A 06007" => "55",
    # SiBrochure — the edition, or the variant name for the derived products
    "BIPM SI Brochure 9e v3.01 (2019/2024, E)" => "9e",
    "BIPM SI Brochure sur le SI 9e v3.01 (2019/2024, F)" => "9e",
    "BIPM SI Brochure Appendix 3" => "Appendix 3",
    "BIPM SI Brochure Concise" => "Concise",
    "BIPM SI Brochure FAQ" => "FAQ",
    # Mep — the MEP code, or the report code for the Rapport variant
    "SI MEP A1" => "A1",
    "SI MEP KUPRTM" => "KUPRTM",
    "Rapport BIPM-2019/05" => "BIPM-2019/05",
    "BIPM SI MEP S1 Appendix 2 Part 1.1" => "S1",
    "BIPM Rapport BIPM-2019/05 Appendix 2 Part 1" => "BIPM-2019/05",
    # Guide
    "CCL-GD-MeP-1" => "1",
    "CCEM-GD-RSI-1" => "1",
    "BIPM CCM-GD-RSI-2 Appendix 2 Part 3.2" => "2",
  }.freeze

  LEAVES = %i[
    CommitteeDocument Meeting MetrologiaArticle SiBrochure Mep Guide
  ].freeze
end

RSpec.describe "Pubid::Bipm index key (root.number)" do
  def parse(str)
    Pubid::Bipm::Identifier.parse(str)
  end

  # The structural half of the tripwire. The examples below prove the *effect*
  # (a String number) but are load-order dependent; these assertions read the
  # attribute definitions directly, so they fail immediately and always.
  describe "number resolves as a plain :string, base and leaves alike" do
    it "declares :string on the shared base" do
      expect(Pubid::Bipm::Identifier.attributes[:number].type)
        .to eq(Lutaml::Model::Type::String)
    end

    BipmIndexKeySpec::LEAVES.each do |leaf|
      it "#{leaf} inherits the :string number" do
        klass = Pubid::Bipm::Identifiers.const_get(leaf)
        expect(klass.attributes[:number].type)
          .to eq(Lutaml::Model::Type::String)
      end
    end
  end

  describe "root.number is the family's index key" do
    BipmIndexKeySpec::KEYS.each do |ref, key|
      it "#{ref} keys on #{key.inspect}" do
        id = parse(ref)
        expect(id.root.number.to_s).to eq(key)
        expect(id.root.number.to_s).not_to be_empty
      end
    end
  end

  describe "the number attribute resolves as a plain String" do
    BipmIndexKeySpec::KEYS.each_key do |ref|
      it "#{ref} carries a String number" do
        id = parse(ref)
        expect(id.number).to be_a(String)
        expect(id.to_hash["number"]).to be_a(String)
      end
    end
  end

  describe "every BIPM identifier is its own root" do
    BipmIndexKeySpec::KEYS.each_key do |ref|
      it "#{ref} roots to itself" do
        id = parse(ref)
        expect(id.root).to equal(id)
      end
    end
  end

  describe "the number survives a from_hash round-trip" do
    BipmIndexKeySpec::KEYS.each do |ref, key|
      it "#{ref} still keys on #{key.inspect} after from_hash" do
        id = parse(ref)
        rebuilt = Pubid::Bipm::Identifier.from_hash(id.to_hash)
        expect(rebuilt.root.number.to_s).to eq(key)
        expect(rebuilt.to_s).to eq(id.to_s)
      end
    end
  end

  describe "clustering" do
    it "puts every article of one Metrologia volume in one bucket" do
      keys = [
        "Metrologia 51",
        "Metrologia 51 1",
        "Metrologia 51 1 128",
        "Metrologia 51 2 271",
      ].map { |ref| parse(ref).root.number.to_s }

      expect(keys.uniq).to eq(["51"])
    end

    it "separates distinct Metrologia volumes" do
      expect(parse("Metrologia 51 1 128").root.number.to_s)
        .not_to eq(parse("Metrologia 55 1A 06007").root.number.to_s)
    end

    it "puts the E and F SI Brochure records in one bucket" do
      keys = [
        "BIPM SI Brochure 9e v3.01 (2019/2024, E)",
        "BIPM SI Brochure sur le SI 9e v3.01 (2019/2024, F)",
      ].map { |ref| parse(ref).root.number.to_s }

      expect(keys.uniq).to eq(["9e"])
    end

    it "keys the short and full MEP spellings alike" do
      expect(parse("SI MEP A1").root.number.to_s)
        .to eq(parse("BIPM SI MEP A1 Appendix 2 Part 4.1").root.number.to_s)
    end

    it "keys the short and full Guide spellings alike" do
      expect(parse("CCL-GD-MeP-1").root.number.to_s)
        .to eq(parse("BIPM CCL-GD-MeP-1 Appendix 2 Part 2.2").root.number.to_s)
    end

    it "keys a committee document alike in both print forms" do
      expect(parse("CGPM RES 1 (1927)").root.number.to_s)
        .to eq(parse("Résolution 1 de la CGPM (1927)").root.number.to_s)
    end
  end

  # `number` is derived from another attribute for three of the six families,
  # so excluding that attribute has to clear the key too — otherwise a
  # wildcarded identifier keeps a stale, now-unjustified index key.
  describe "#exclude clears number alongside the attribute it derives from" do
    {
      "Metrologia 51 1 128" => :volume,
      "BIPM SI Brochure 9e v3.01 (2019/2024, E)" => :edition,
      "BIPM SI Brochure Appendix 3" => :variant,
      "SI MEP A1" => :mep_code,
      "Rapport BIPM-2019/05" => :report_code,
    }.each do |ref, attr|
      it "#{ref} loses its key under exclude(#{attr})" do
        id = parse(ref)
        expect(id.number).not_to be_nil

        excluded = id.exclude(attr)
        expect(excluded.public_send(attr)).to be_nil
        expect(excluded.number).to be_nil
      end
    end

    it "keeps the key when an unrelated attribute is excluded" do
      expect(parse("Metrologia 51 1 128").exclude(:issue).number).to eq("51")
    end

    it "leaves a family whose number is its own document number alone" do
      # CommitteeDocument/Meeting/Guide store a real document number, so no
      # source attribute exists to clear it.
      expect(parse("CCTF REC 2 (2012)").exclude(:year).number).to eq("2")
    end
  end

  # The two groups that stay number-less on purpose: 7 of the 7,922 published
  # rows (99.91% coverage). Pinned so the gap stays visible — filling them would
  # move `urn:bipm:cgpm:decl::1889`'s documented empty number segment and the
  # nil assertions in identifier_spec.rb / partial_spec.rb.
  describe "the documented number-less exceptions" do
    it "leaves an ordinal-less committee declaration number-less" do
      id = parse("CGPM DECL (1889)")
      expect(id.number).to be_nil
      expect(id.root.number.to_s).to be_empty
    end

    it "keeps that declaration's empty URN number segment" do
      expect(parse("CGPM DECL (1889)").to_urn)
        .to eq("urn:bipm:cgpm:decl::1889")
    end

    it "leaves the journal-level Metrologia record number-less" do
      id = parse("Metrologia")
      expect(id.number).to be_nil
      expect(id.root.number.to_s).to be_empty
    end
  end
end
