# frozen_string_literal: true

require "spec_helper"

# Loose consumer reference forms.
#
# `Relaton::Bipm::Bibliography` could not use pubid as its query parser: it
# parses user references with a bespoke regex grammar (`Relaton::Bipm::Id`)
# because `Pubid::Bipm.parse` rejected the spellings below. Every one of them
# is a committed example in relaton's
# `spec/bipm/relaton/bipm/bibliography_spec.rb`, so they are real consumer
# input, not hypotheticals.
#
# All of these are NORMALIZING parses — the identifier renders back in BIPM's
# own canonical spelling, never the input. That is the whole point: a loose
# reference has to produce an identifier equal to the one the index row carries.
# Because they are not byte-exact they must NEVER go into
# `spec/fixtures/bipm/identifiers/pass/` (the `CIPM/2005-06(REV)` precedent) —
# their expectations live here instead.
module BipmLooseSpec
  # loose spelling => the canonical BIPM spelling it normalizes to.
  CANONICAL = {
    # "<group> Meeting <n>" word order (relaton's `parse_group_type` with the
    # type word "Meeting"); pubid printed only "<group> <n>th Meeting".
    "CCTF Meeting 14 (1999)" => "CCTF 14th Meeting (1999)",
    "CGPM Meeting 1 (1889)" => "CGPM 1st Meeting (1889)",
    "CIPM Meeting 43" => "CIPM 43rd Meeting",
    "CIPM Réunion 43" => "CIPM 43<sup>e</sup> réunion",
    # The plain "e" French ordinal (relaton's `parse_group_num`); pubid printed
    # only the "<sup>e</sup>" markup form.
    "CIPM 111e Réunion (2022)" => "CIPM 111<sup>e</sup> réunion (2022)",
    "CCAUV 10e réunion (2015)" => "CCAUV 10<sup>e</sup> réunion (2015)",
    # A French type name in the group-leading (English) word order.
    "CIPM Décision 101-1 (2012)" => "Décision 101-1 du CIPM (2012)",
    "CGPM Résolution 1 (1889)" => "Résolution 1 de la CGPM (1889)",
    # The historic committee name.
    "CCDS Recommendation 2 (2009)" => "CCTF Recommendation 2 (2009)",
    "CCDS REC 2 (2009)" => "CCTF REC 2 (2009)",
    # Two-letter language codes.
    "CCTF REC 2 (2009, EN)" => "CCTF REC 2 (2009, E)",
    "CCTF REC 2 (2009, FR)" => "CCTF REC 2 (2009, F)",
    # The bare and sectioned SI Brochure. The prefix-less edition form is the
    # docnumber `si-brochure.yaml` actually stores, and it is also what
    # `Relaton::Bipm::Bibliography.search` produces after it strips "BIPM ".
    "SI Brochure 9e v3.01 (2019/2024, E)" =>
      "BIPM SI Brochure 9e v3.01 (2019/2024, E)",
    "SI Brochure sur le SI 9e v3.01 (2019/2024, F)" =>
      "BIPM SI Brochure sur le SI 9e v3.01 (2019/2024, F)",
    "SI Brochure" => "BIPM SI Brochure",
    "SI Brochure Part 1" => "BIPM SI Brochure Part 1",
    "BIPM SI Brochure Part 1" => "BIPM SI Brochure Part 1",
    # "Declaration"/"Déclaration" parsed but mapped to NO type code, so the
    # renderer emitted a corrupt "CGPM  1 (1971)". BIPM's source data prints
    # DECL as "Statement" in both languages, which is what they normalize to.
    "CGPM Declaration 1 (1971)" => "CGPM Statement 1 (1971)",
    "Déclaration 1 du CGPM (1971)" => "Statement 1 de la CGPM (1971)",
  }.freeze

  # The hand-off's contract table: loose form => [class, number].
  SHAPES = {
    "CCTF Meeting 14 (1999)" => [Pubid::Bipm::Identifiers::Meeting, "14"],
    "CGPM Meeting 1 (1889)" => [Pubid::Bipm::Identifiers::Meeting, "1"],
    "CIPM Meeting 43" => [Pubid::Bipm::Identifiers::Meeting, "43"],
    "CIPM 111e Réunion (2022)" => [Pubid::Bipm::Identifiers::Meeting, "111"],
    "CIPM Décision 101-1 (2012)" =>
      [Pubid::Bipm::Identifiers::CommitteeDocument, "101-1"],
    "CCDS Recommendation 2 (2009)" =>
      [Pubid::Bipm::Identifiers::CommitteeDocument, "2"],
    "CCTF REC 2 (2009, EN)" =>
      [Pubid::Bipm::Identifiers::CommitteeDocument, "2"],
    "SI Brochure" => [Pubid::Bipm::Identifiers::SiBrochure, nil],
    "SI Brochure Part 1" => [Pubid::Bipm::Identifiers::SiBrochure, nil],
  }.freeze

  # Real rows lifted from the published `relaton-data-bipm` `index-v2.yaml`
  # (branch v2). A loose reference has to reduce to the row it resolves to, or
  # relaton cannot replace `Id#==` with pubid-to-pubid matching.
  #
  # The reduction is `#exclude(:language, :form)`, the BIPM equivalent of the
  # `stem` every other pubid-backed flavor uses: committee-document and meeting
  # rows are stored language- and form-neutral (verified — all 1348 + 367 of
  # them), while a loose reference may name a language and always names a form.
  ROWS = {
    "CCTF Meeting 14 (1999)" => {
      "_type" => "pubid:bipm:meeting", "group" => "CCTF",
      "number" => "14", "year" => 1999
    },
    "CGPM Meeting 1 (1889)" => {
      "_type" => "pubid:bipm:meeting", "group" => "CGPM",
      "number" => "1", "year" => 1889
    },
    "CIPM 111e Réunion (2022)" => {
      "_type" => "pubid:bipm:meeting", "group" => "CIPM",
      "number" => "111", "year" => 2022
    },
    # The four spellings of ONE decision — short, short-with-language, English
    # long and French long — must all reduce to the same stored row, or a
    # consumer would resolve them to different documents.
    "CIPM DECN 101-1 (2012)" => {
      "_type" => "pubid:bipm:committee-document", "group" => "CIPM",
      "type_code" => "DECN", "number" => "101-1", "year" => 2012
    },
    "CIPM DECN 101-1 (2012, EN)" => {
      "_type" => "pubid:bipm:committee-document", "group" => "CIPM",
      "type_code" => "DECN", "number" => "101-1", "year" => 2012
    },
    "CIPM Decision 101-1 (2012)" => {
      "_type" => "pubid:bipm:committee-document", "group" => "CIPM",
      "type_code" => "DECN", "number" => "101-1", "year" => 2012
    },
    "CIPM Décision 101-1 (2012)" => {
      "_type" => "pubid:bipm:committee-document", "group" => "CIPM",
      "type_code" => "DECN", "number" => "101-1", "year" => 2012
    },
    "CCDS Recommendation 2 (2009)" => {
      "_type" => "pubid:bipm:committee-document", "group" => "CCTF",
      "type_code" => "REC", "number" => "2", "year" => 2009
    },
    "CCTF REC 2 (2009, EN)" => {
      "_type" => "pubid:bipm:committee-document", "group" => "CCTF",
      "type_code" => "REC", "number" => "2", "year" => 2009
    },
  }.freeze
end

RSpec.describe "Pubid::Bipm loose consumer forms" do
  describe "normalization to the canonical BIPM spelling" do
    BipmLooseSpec::CANONICAL.each do |loose, canonical|
      context loose.inspect do
        subject(:id) { Pubid::Bipm.parse(loose) }

        it "renders as #{canonical.inspect}" do
          expect(id.to_s).to eq(canonical)
        end

        it "equals the canonical form's identifier" do
          expect(id).to eq(Pubid::Bipm.parse(canonical))
        end

        it "serializes identically to the canonical form" do
          expect(id.to_hash).to eq(Pubid::Bipm.parse(canonical).to_hash)
        end

        it "round-trips through to_hash/from_hash" do
          hash = id.to_hash
          expect(Pubid::Bipm::Identifier.from_hash(hash).to_hash).to eq(hash)
        end
      end
    end
  end

  describe "identifier type and index key" do
    BipmLooseSpec::SHAPES.each do |loose, (klass, number)|
      it "#{loose.inspect} is a #{klass.name.split('::').last} numbered " \
         "#{number.inspect}" do
        id = Pubid::Bipm.parse(loose)
        expect(id).to be_a(klass)
        expect(id.root.number).to eq(number)
      end
    end
  end

  describe "reduction to the index row it resolves to" do
    BipmLooseSpec::ROWS.each do |loose, row|
      it "#{loose.inspect} stems to its stored row" do
        query = Pubid::Bipm.parse(loose)
        stored = Pubid::Bipm::Identifier.from_hash(row)
        expect(query.exclude(:language, :form))
          .to eq(stored.exclude(:language, :form))
      end
    end
  end

  # The SI Brochure reference names no edition, so it is a partial reference:
  # `number` stays nil and it wildcards every edition, exactly as a date-less
  # "CCTF REC 2" wildcards every year. relaton's own `Id` collapses ALL SI
  # Brochure references to `{group: "SI", type: "Brochure"}`, so this loses it
  # nothing.
  describe "SI Brochure partial references" do
    it "leaves the bare form's edition, version and number nil" do
      id = Pubid::Bipm.parse("SI Brochure")
      expect(id.edition).to be_nil
      expect(id.version).to be_nil
      expect(id.variant).to be_nil
      expect(id.number).to be_nil
    end

    # "Part N" points at a section INSIDE the brochure, not a separate record
    # (there is no si-brochure-part-1.yaml upstream, and relaton's `Id` drops
    # `part` when matching). It rides in the shared `part` attribute and stays
    # out of the index key — the same rule the MEP/guide "Part N.M" tail obeys.
    it "carries \"Part N\" as a section pointer, not a number" do
      id = Pubid::Bipm.parse("SI Brochure Part 1")
      expect(id.part).to eq("1")
      expect(id.number).to be_nil
      expect(id.variant).to be_nil
    end

    it "keeps the derived products distinct from a section" do
      expect(Pubid::Bipm.parse("SI Brochure Concise").variant).to eq("Concise")
      expect(Pubid::Bipm.parse("SI Brochure Appendix 3").variant)
        .to eq("Appendix 3")
    end

    # The real `index-v2` row, so the wildcard is proven against stored data
    # rather than against another parse. Excluding `:edition` also clears
    # `number` (it is in NUMBER_SOURCE_ATTRIBUTES), which is what stops the
    # reduced row keeping a stale index key the query never had.
    context "against the stored SI Brochure row" do
      let(:row) do
        Pubid::Bipm::Identifier.from_hash(
          "_type" => "pubid:bipm:si-brochure", "number" => "9e",
          "language" => "E", "edition" => "9e", "version" => "v3.01",
          "years" => "2019/2024"
        )
      end

      # The consumer branches on exactly this: an edition-less SiBrochure query
      # matches any SiBrochure row, which is what relaton's `Id#id_hash`
      # collapse to `{group: "SI", type: "Brochure"}` already meant.
      it "leaves the query edition-less while the row carries one" do
        expect(row.edition).to eq("9e")
        expect(Pubid::Bipm.parse("SI Brochure").edition).to be_nil
        expect(Pubid::Bipm.parse("SI Brochure Part 1").edition).to be_nil
      end

      it "wildcards every edition of the stored row" do
        reduce = %i[edition version years language part]
        ["SI Brochure", "SI Brochure Part 1"].each do |ref|
          expect(Pubid::Bipm.parse(ref).exclude(*reduce))
            .to eq(row.exclude(*reduce))
          expect(row.exclude(*reduce).number).to be_nil
        end
      end

      # The full edition form is not a partial reference: it must still match
      # the row exactly, without any reduction at all.
      it "matches the row exactly when the reference names the edition" do
        expect(Pubid::Bipm.parse("SI Brochure 9e v3.01 (2019/2024, E)"))
          .to eq(row)
      end
    end
  end

  # Explicitly NOT changed: "CCTF Recommendation 2009-02" reads as the literal
  # number "2009-02" while the index keys the same document under "2". The
  # reading is genuinely ambiguous — NNNN-NN is a real BIPM number form
  # elsewhere ("CIPM 2005-06") — so the consumer keeps its full-scan fallback.
  describe "the year-number spelling stays ambiguous" do
    it "reads \"CCTF Recommendation 2009-02\" as the number 2009-02" do
      id = Pubid::Bipm.parse("CCTF Recommendation 2009-02")
      expect(id.number).to eq("2009-02")
      expect(id.year).to be_nil
    end

    it "still reads the bare MRA form as a number" do
      expect(Pubid::Bipm.parse("CIPM 2005-06").number).to eq("2005-06")
    end
  end

  # "Action" and "Statement" are in BOTH TYPE_NAME_EN and TYPE_NAME_FR, so the
  # English and the French group-leading rules both consume these strings
  # whole. That is the one case where alternation ORDER decides the outcome —
  # verified: putting committee_group_fr first turns "CIPM Action 5 (2010)"
  # into the French "Action 5 du CIPM (2010)" with language "F", i.e. a
  # different record. This block is the guard against that reordering.
  describe "type words shared by both languages" do
    it "reads \"Action\" as the English long form" do
      id = Pubid::Bipm.parse("CIPM Action 5 (2010)")
      expect(id.language).to eq("E")
      expect(id.to_s).to eq("CIPM Action 5 (2010)")
    end

    it "reads \"Statement\" as the English long form" do
      id = Pubid::Bipm.parse("CGPM Statement 1 (1971)")
      expect(id.type_code).to eq("DECL")
      expect(id.language).to eq("E")
    end
  end

  # A French type word says the reference wants the French text, so it is kept
  # as `language: "F"` (what the canonical French rules already do) rather than
  # discarded. A consumer can always widen a language away with
  # `#exclude(:language)`; it could never recover one pubid dropped.
  describe "the language a French type word implies" do
    it "marks the French spelling French and the English one English" do
      expect(Pubid::Bipm.parse("CIPM Décision 101-1 (2012)").language)
        .to eq("F")
      expect(Pubid::Bipm.parse("CIPM Decision 101-1 (2012)").language)
        .to eq("E")
    end

    it "still reduces both to one document under the stem" do
      fr = Pubid::Bipm.parse("CIPM Décision 101-1 (2012)")
      en = Pubid::Bipm.parse("CIPM Decision 101-1 (2012)")
      expect(fr.exclude(:language, :form)).to eq(en.exclude(:language, :form))
    end
  end

  describe "the historic CCDS committee name" do
    it "resolves to CCTF and never stores the alias" do
      id = Pubid::Bipm.parse("CCDS REC 2 (2009)")
      expect(id.group).to eq("CCTF")
      expect(id.to_hash["group"]).to eq("CCTF")
    end
  end

  describe "two-letter language codes" do
    it "stores the one-letter code BIPM prints" do
      expect(Pubid::Bipm.parse("CCTF REC 2 (2009, EN)").language).to eq("E")
      expect(Pubid::Bipm.parse("CCTF REC 2 (2009, FR)").language).to eq("F")
    end

    it "still accepts the one-letter codes" do
      expect(Pubid::Bipm.parse("CCTF REC 2 (2009, E)").language).to eq("E")
      expect(Pubid::Bipm.parse("CCTF REC 2 (2009, F)").language).to eq("F")
    end

    # The SI Brochure shares the `lang` rule, so it accepts the two-letter
    # codes too. That falls out of the rule rather than being asked for, so
    # pin it — a change to either rule would otherwise regress it silently.
    it "normalizes them on the SI Brochure too" do
      id = Pubid::Bipm.parse("BIPM SI Brochure 9e v3.01 (2019/2024, EN)")
      expect(id.language).to eq("E")
      expect(id.to_s).to eq("BIPM SI Brochure 9e v3.01 (2019/2024, E)")
    end
  end

  describe "the DECL type word" do
    it "maps every spelling onto the DECL code" do
      %w[DECL Statement Declaration].each do |word|
        expect(Pubid::Bipm.parse("CGPM #{word} 1 (1971)").type_code)
          .to eq("DECL")
      end
      expect(Pubid::Bipm.parse("Déclaration 1 du CGPM (1971)").type_code)
        .to eq("DECL")
    end
  end
end
