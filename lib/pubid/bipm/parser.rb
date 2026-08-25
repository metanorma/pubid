# frozen_string_literal: true

require "parslet"

module Pubid
  module Bipm
    # Parslet grammar for the four BIPM identifier families. The root branches
    # by leading token / shape; each alternative is wrapped in a distinct key
    # (:committee_short, :meeting_en, …) so the Builder can dispatch on the
    # matched branch without re-inspecting the string.
    #
    # Group and type-word alternations are built from the shared vocabularies on
    # {Identifier} (sorted longest-first so e.g. "CCTF" is tried before "CCT").
    class Parser < Parslet::Parser
      # --- primitives ---
      rule(:space) { str(" ") }
      rule(:digits) { match["0-9"].repeat(1) }
      rule(:alnum) { match["0-9A-Za-z"].repeat(1) }
      # Number, preserved as a string: digits with optional hyphenated parts.
      rule(:number) do
        (digits >> (str("-") >> digits).repeat).as(:number)
      end
      rule(:year) { match["0-9"].repeat(4, 4).as(:year) }
      # "E"/"F" as BIPM prints them, plus the two-letter codes consumer
      # references use (longest first, so "EN" is never read as a bare "E").
      rule(:lang) do
        (str("EN") | str("FR") | match["EF"]).as(:language)
      end
      # "(YYYY)" or "(YYYY, E)"
      rule(:year_paren) do
        str("(") >> year >> (str(", ") >> lang).maybe >> str(")")
      end
      rule(:year_paren_nolang) { str("(") >> year >> str(")") }

      # Longest-first alternation over a list of literal tokens, so a token that
      # is a prefix of another (e.g. "CCT" of "CCTF") never shadows it.
      def alternation(tokens)
        tokens.sort_by { |t| -t.length }.map { |t| str(t) }.reduce(:|)
      end

      rule(:group) { alternation(Identifier::PARSEABLE_GROUPS).as(:group) }

      rule(:type_abbrev) do
        alternation(Identifier::TYPE_CODES).as(:type_word)
      end
      rule(:type_name_en) do
        names = Identifier::TYPE_NAME_EN.values.uniq + ["Declaration"]
        alternation(names).as(:type_word)
      end
      rule(:type_name_fr) do
        names = Identifier::TYPE_NAME_FR.values.uniq + ["Déclaration"]
        alternation(names).as(:type_word)
      end
      rule(:connective) { str("de la") | str("du") }
      rule(:ordinal) { str("st") | str("nd") | str("rd") | str("th") }
      # The word naming a meeting in French. BIPM prints it lowercase; a
      # consumer reference capitalizes it, as relaton's `Id::TYPES` does.
      rule(:meeting_word_fr) { str("Réunion") | str("réunion") }

      # --- committee documents ---
      # The trailing "(YYYY)" date is optional (`.maybe`) so a partial reference
      # that omits it — e.g. "CCTF REC 2" — still parses, leaving :year absent.
      rule(:committee_short) do
        (group >> space >> type_abbrev >>
          (space >> number).maybe >> (space >> year_paren).maybe)
          .as(:committee_short)
      end
      rule(:committee_long_en) do
        (group >> space >> type_name_en >>
          (space >> number).maybe >> (space >> year_paren_nolang).maybe)
          .as(:committee_long_en)
      end
      rule(:committee_long_fr) do
        (type_name_fr >> (space >> number).maybe >> space >>
          connective >> space >> group >> (space >> year_paren_nolang).maybe)
          .as(:committee_long_fr)
      end
      # Loose consumer form: a French type name in the English (group-leading)
      # word order, e.g. "CIPM Décision 101-1 (2012)". BIPM never prints this,
      # so it renders back as the canonical "Décision 101-1 du CIPM (2012)".
      # Tried after `committee_long_en`, which is what keeps the words both
      # languages share ("Action", "Statement") English.
      rule(:committee_group_fr) do
        (group >> space >> type_name_fr >>
          (space >> number).maybe >> (space >> year_paren_nolang).maybe)
          .as(:committee_long_fr)
      end

      # Bare MRA-interpretation form: a group directly followed by a document
      # number with no type word (e.g. "CIPM 2005-06"). Tried last, so typed
      # committee documents and meetings always win; only fires when a digit
      # follows the group and the string is fully consumed.
      rule(:committee_bare) do
        (group >> space >> number >> (space >> year_paren).maybe)
          .as(:committee_bare)
      end

      # --- meetings ---
      # Canonical: "<group> <n><ordinal> Meeting [(YYYY)]". The second branch is
      # the loose consumer word order "<group> Meeting <n>", which relaton's
      # bespoke grammar accepts; both build the same tree, so the loose form
      # renders back in the canonical spelling.
      rule(:meeting_en) do
        ((group >> space >> number >> ordinal >> space >> str("Meeting") >>
          (space >> year_paren).maybe) |
         (group >> space >> str("Meeting") >> space >> number >>
           (space >> year_paren).maybe)).as(:meeting_en)
      end
      # Canonical: "<group> <n><sup>e</sup> réunion [(YYYY)]". The second and
      # third branches are the loose consumer spellings — the plain "e" ordinal
      # and the "<group> Réunion <n>" word order.
      rule(:meeting_fr) do
        ((group >> space >> number >> str("<sup>e</sup>") >> space >>
          str("réunion") >> (space >> year_paren).maybe) |
         (group >> space >> number >> str("e") >> space >> meeting_word_fr >>
           (space >> year_paren).maybe) |
         (group >> space >> meeting_word_fr >> space >> number >>
           (space >> year_paren).maybe)).as(:meeting_fr)
      end

      # --- Metrologia journal ---
      rule(:metrologia) do
        (str("Metrologia") >>
          (space >> digits.as(:volume) >>
            (space >> alnum.as(:issue) >>
              (space >> alnum.as(:article)).maybe).maybe).maybe).as(:metrologia)
      end

      # --- SI Brochure ---
      rule(:edition) { (digits >> str("e")).as(:edition) }
      rule(:version) { (str("v") >> match["0-9."].repeat(1)).as(:version) }
      rule(:years) { (digits >> (str("/") >> digits).maybe).as(:years) }
      # The "BIPM " prefix is optional, as it is on the variant and section
      # rules: `si-brochure.yaml` stores the docnumber WITHOUT it, and
      # `Relaton::Bipm::Bibliography.search` strips a leading "BIPM " before it
      # ever reaches pubid. Either spelling renders back with the prefix.
      rule(:si_brochure) do
        ((str("BIPM SI Brochure") | str("SI Brochure")) >> space >>
          (str("sur le SI") >> space).maybe >>
          edition >> space >> version >> space >>
          str("(") >> years >> str(", ") >> lang >> str(")")).as(:si_brochure)
      end

      # --- SI Brochure appendices / derived products ---
      # The full primary-docidentifier content the relaton crawler indexes by,
      # e.g. "BIPM SI Brochure Appendix 3" / "…Concise" / "…FAQ". The bare
      # "SI Brochure Appendix 3" docnumber form is accepted too (rendered back
      # with the "BIPM " prefix, matching the base SI Brochure record).
      rule(:brochure_variant) do
        ((str("Appendix") >> space >> digits) | str("Concise") | str("FAQ"))
          .as(:variant)
      end
      rule(:si_brochure_variant) do
        ((str("BIPM SI Brochure") | str("SI Brochure")) >> space >>
          brochure_variant).as(:si_brochure_variant)
      end

      # Bare and sectioned SI Brochure references: "SI Brochure",
      # "SI Brochure Part 1". Neither names an edition, so both are partial
      # references whose `number` stays nil and which wildcard every edition —
      # the same reading a date-less "CCTF REC 2" gets. "Part N" points at a
      # section INSIDE the brochure, not a separate record, so it rides in the
      # shared `part` attribute and stays out of the index key, exactly as the
      # MEP/guide "Part N.M" tail does. Listed after the edition and variant
      # rules for readability, not for correctness: Parslet threads
      # `consume_all` down through an alternation, so an alternative that
      # matches only a PREFIX ("SI Brochure" of "SI Brochure Concise") counts
      # as a failure and the next one is tried whatever the order. Order only
      # decides between two alternatives that BOTH consume the whole input.
      rule(:si_brochure_section) do
        ((str("BIPM SI Brochure") | str("SI Brochure")) >>
          (space >> str("Part") >> space >> digits.as(:part)).maybe)
          .as(:si_brochure_section)
      end

      # Shared "Appendix N [Annex N] Part N[.M]" tail carried by the full
      # docidentifier content of MEPs and CC guides (the "Appendix 2 Part 1.1"
      # or "Appendix 2 Annex 2 Part 1" suffix on "BIPM SI MEP …" etc.).
      rule(:appendix_part) do
        str("Appendix") >> space >> digits.as(:appendix) >>
          (space >> str("Annex") >> space >> digits.as(:annex)).maybe >>
          space >> str("Part") >> space >>
          (digits >> (str(".") >> digits).maybe).as(:part)
      end

      # --- Mises en pratique (MEP) ---
      # Two index-relevant spellings: the short docnumber ("SI MEP S1",
      # "Rapport BIPM-2019/05") and the full "BIPM …" primary-docidentifier
      # content the crawler actually keys on ("BIPM SI MEP S1 Appendix 2 Part
      # 1.1"). The renderer reproduces whichever the identifier carries.
      rule(:mep_code) { match["0-9A-Za-z"].repeat(1).as(:mep_code) }
      rule(:report_code) do
        (str("BIPM-") >> digits >> str("/") >> digits).as(:report_code)
      end
      rule(:mep_body) do
        (str("SI MEP") >> space >> mep_code) |
          (str("Rapport") >> space >> report_code)
      end
      rule(:mep) do
        ((str("BIPM") >> space >> mep_body >> space >> appendix_part) |
          mep_body).as(:mep)
      end

      # --- Consultative-Committee guides ---
      # "<committee>-GD-<kind>-<number>" (e.g. "CCL-GD-MeP-1"), and its full
      # "BIPM … Appendix 2 Part 2.2" content form. <kind> is "MeP" (mise en
      # pratique) or "RSI" (réalisation du SI). Reuses the shared `group`
      # (committee) and `number` (trailing sequence).
      rule(:guide_kind) { (str("MeP") | str("RSI")).as(:guide_kind) }
      rule(:guide_body) do
        group >> str("-GD-") >> guide_kind >> str("-") >> digits.as(:number)
      end
      rule(:guide) do
        ((str("BIPM") >> space >> guide_body >> space >> appendix_part) |
          guide_body).as(:guide)
      end

      # After a leading group token, the shape after the first space decides:
      # a digit → meeting; a type word → committee.
      rule(:group_leading) do
        meeting_en | meeting_fr | committee_short | committee_long_en |
          committee_group_fr | committee_bare
      end

      rule(:identifier) do
        metrologia | si_brochure | si_brochure_variant | si_brochure_section |
          mep | guide | committee_long_fr | group_leading
      end

      root(:identifier)

      def self.parse(input)
        new.parse(input)
      end
    end
  end
end
