# frozen_string_literal: true

require "spec_helper"

# BIPM's MR string (issue #142's contract: distinct documents never collide on
# `to_mr_string`, and `to_slug` is filename-safe).
#
# BIPM inherits none of the base ::Pubid::Identifier MR hooks usefully: it keeps
# its publisher as a constant (so `mr_publisher` was nil), its year as an
# :integer rather than a Components::Date (`mr_year` nil), its edition as a
# :string rather than a Components::Edition (the base `mr_edition` raised
# NoMethodError on `edition.number`) and its own `type_code` rather than a
# typed_stage (`mr_type` nil). Before this change the 90 pass-fixture
# identifiers collapsed onto 21 distinct MR strings — "" for 41 of them — and
# `to_slug` is what consumers use as an output FILENAME.
module BipmMrSpec
  # One representative per family, plus the corners: hyphenated ordinals, the
  # bare CIPM MRA form, the language suffixes, the slash-bearing MEP report
  # code and the space-bearing SI Brochure variant.
  STRINGS = {
    # CommitteeDocument — group is in the number segment, or CCTF REC 2 and
    # CCEM REC 2 would collide.
    "CCTF REC 2 (2012)" => "bipm.rec.cctf-2.2012",
    "CCTF REC 2 (2012, E)" => "bipm.rec.cctf-2.2012.e",
    "CCTF REC 2 (2012, F)" => "bipm.rec.cctf-2.2012.f",
    "CCTF REC 2" => "bipm.rec.cctf-2",
    "JCRB ACT 10-1 (2003)" => "bipm.act.jcrb-10-1.2003",
    "CGPM DECL (1889)" => "bipm.decl.cgpm.1889",
    "CIPM 2005-06" => "bipm.cipm-2005-06",
    # Meeting
    "CGPM 17th Meeting (1983)" => "bipm.meeting.cgpm-17.1983",
    "CIPM 100-1th Meeting (2011)" => "bipm.meeting.cipm-100-1.2011",
    # MetrologiaArticle — the full volume/issue/article triple lives here, which
    # is what restores per-article distinctness after `number` was made the
    # (clustering) volume.
    "Metrologia" => "bipm.metrologia",
    "Metrologia 51" => "bipm.metrologia.51",
    "Metrologia 51 1" => "bipm.metrologia.51-1",
    "Metrologia 51 1 128" => "bipm.metrologia.51-1-128",
    "Metrologia 55 1A 06007" => "bipm.metrologia.55-1a-06007",
    "Metrologia 42 3 S138" => "bipm.metrologia.42-3-s138",
    # SiBrochure
    "BIPM SI Brochure 9e v3.01 (2019/2024, E)" => "bipm.si-brochure.9e-v3-01.e",
    "BIPM SI Brochure sur le SI 9e v3.01 (2019/2024, F)" =>
      "bipm.si-brochure.9e-v3-01.f",
    "BIPM SI Brochure Appendix 3" => "bipm.si-brochure.appendix-3",
    "BIPM SI Brochure Concise" => "bipm.si-brochure.concise",
    "BIPM SI Brochure FAQ" => "bipm.si-brochure.faq",
    # Mep — the report code carries a `/`, which must not survive into a slug.
    "SI MEP A1" => "bipm.mep.a1",
    "SI MEP KUPRTM" => "bipm.mep.kuprtm",
    "Rapport BIPM-2019/05" => "bipm.mep.bipm-2019-05",
    # Guide — group + kind, or CCL-GD-MeP-1 and CCEM-GD-RSI-1 would collide.
    "CCL-GD-MeP-1" => "bipm.guide.ccl-mep-1",
    "CCEM-GD-RSI-1" => "bipm.guide.ccem-rsi-1",
  }.freeze

  # Genuinely distinct documents that must never share a slug.
  DISTINCT = [
    "CCTF REC 2 (2012)",
    "CCEM REC 2 (2012)",
    "CCTF REC 2 (2012, E)",
    "CCTF REC 2 (2012, F)",
    "CCTF REC 3 (2012)",
    "CCTF REC 2 (2015)",
    "CCTF RES 2 (2012)",
    "CGPM 17th Meeting (1983)",
    "CIPM 17th Meeting (1983)",
    "Metrologia 51 1 128",
    "Metrologia 51 1 129",
    "Metrologia 51 2 128",
    "Metrologia 55 1 128",
    "Metrologia 51 1",
    "Metrologia 51",
    "Metrologia",
    "BIPM SI Brochure 9e v3.01 (2019/2024, E)",
    "BIPM SI Brochure sur le SI 9e v3.01 (2019/2024, F)",
    "BIPM SI Brochure Appendix 3",
    "BIPM SI Brochure Concise",
    "BIPM SI Brochure FAQ",
    "SI MEP A1",
    "SI MEP K1",
    "SI MEP KUPRTM",
    "Rapport BIPM-2019/05",
    "CCL-GD-MeP-1",
    "CCL-GD-MeP-2",
    "CCEM-GD-RSI-1",
    "CCM-GD-RSI-1",
  ].freeze
end

RSpec.describe "Pubid::Bipm MR string" do
  def parse(str)
    Pubid::Bipm::Identifier.parse(str)
  end

  describe "per-family shape" do
    BipmMrSpec::STRINGS.each do |ref, mr|
      it "#{ref} renders #{mr.inspect}" do
        expect(parse(ref).to_mr_string).to eq(mr)
      end
    end
  end

  describe "to_slug equals to_mr_string (BIPM adds no projection)" do
    BipmMrSpec::STRINGS.each_key do |ref|
      it ref do
        id = parse(ref)
        expect(id.to_slug).to eq(id.to_mr_string)
      end
    end
  end

  # `to_slug` is used as an output filename, so this must hold for EVERY
  # identifier the flavor can parse, not just the table above.
  describe "every pass fixture yields a non-empty, filename-safe slug" do
    pass_dir = File.join(__dir__, "../../fixtures/bipm/identifiers/pass")

    Dir.glob(File.join(pass_dir, "*.txt")).each do |file|
      it File.basename(file) do
        identifiers = File.readlines(file).map(&:strip).reject do |line|
          line.empty? || line.start_with?("#")
        end
        expect(identifiers).not_to be_empty

        bad = identifiers.reject do |ref|
          slug = Pubid::Bipm::Identifier.parse(ref).to_slug
          !slug.empty? && slug.match?(/\A[a-z0-9._-]+\z/)
        end

        expect(bad).to be_empty, "unsafe or empty BIPM slugs: #{bad.inspect}"
      end
    end
  end

  describe "distinct documents never collide" do
    it "produces a distinct slug for each" do
      slugs = BipmMrSpec::DISTINCT.to_h { |ref| [ref, parse(ref).to_mr_string] }
      duplicates = slugs.group_by { |_, v| v }.select { |_, v| v.size > 1 }
      expect(duplicates).to be_empty, lambda {
        "colliding MR strings: #{duplicates.inspect}"
      }
    end
  end

  # MR is a canonical DOCUMENT slug, so alternate print spellings of one
  # document share it on purpose. The URN already collapses the first two.
  describe "deliberate collapses" do
    it "ignores the short/long committee print form" do
      expect(parse("CCTF REC 2 (2012, F)").to_mr_string)
        .to eq(parse("Recommandation 2 du CCTF (2012)").to_mr_string)
    end

    it "ignores the MEP full-content Appendix/Part tail" do
      expect(parse("SI MEP A1").to_mr_string)
        .to eq(parse("BIPM SI MEP A1 Appendix 2 Part 4.1").to_mr_string)
    end

    it "ignores the Guide full-content Appendix/Part tail" do
      expect(parse("CCL-GD-MeP-1").to_mr_string)
        .to eq(parse("BIPM CCL-GD-MeP-1 Appendix 2 Part 2.2").to_mr_string)
    end

    # Renderers::MrString joins segments with ".", so a dot inside one would
    # break the segment structure; `mr_slug` collapses it like any other
    # non-[a-z0-9] character. The SI Brochure version "v3.01" is the only BIPM
    # value that carries one.
    it "keeps the segment separator out of a number segment" do
      mr = parse("BIPM SI Brochure 9e v3.01 (2019/2024, E)").to_mr_string
      expect(mr.split(".")).to eq(%w[bipm si-brochure 9e-v3-01 e])
    end

    it "keeps the language, which distinguishes real records" do
      expect(parse("CCTF REC 2 (2012, E)").to_mr_string)
        .not_to eq(parse("CCTF REC 2 (2012, F)").to_mr_string)
    end

    # The long French spelling is not merely another rendering: the builder
    # records it as language "F", so it names the French record, which is a
    # distinct file upstream from the language-neutral one.
    it "separates a French spelling from the language-neutral form" do
      expect(parse("CGPM RES 1 (1927)").to_mr_string)
        .not_to eq(parse("Résolution 1 de la CGPM (1927)").to_mr_string)
    end

    it "separates a French réunion from the language-neutral meeting" do
      expect(parse("CCAUV 10th Meeting (2015)").to_mr_string)
        .not_to eq(parse("CCAUV 10<sup>e</sup> réunion (2015)").to_mr_string)
    end
  end
end
