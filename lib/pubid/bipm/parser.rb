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
      rule(:lang) { match["EF"].as(:language) }
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

      rule(:group) { alternation(Identifier::GROUPS).as(:group) }

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
      # Bare MRA-interpretation form: a group directly followed by a document
      # number with no type word (e.g. "CIPM 2005-06"). Tried last, so typed
      # committee documents and meetings always win; only fires when a digit
      # follows the group and the string is fully consumed.
      rule(:committee_bare) do
        (group >> space >> number >> (space >> year_paren).maybe)
          .as(:committee_bare)
      end

      # --- meetings ---
      rule(:meeting_en) do
        (group >> space >> number >> ordinal >> space >>
          str("Meeting") >> (space >> year_paren).maybe).as(:meeting_en)
      end
      rule(:meeting_fr) do
        (group >> space >> number >> str("<sup>e</sup>") >> space >>
          str("réunion") >> (space >> year_paren).maybe).as(:meeting_fr)
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
      rule(:si_brochure) do
        (str("BIPM SI Brochure") >> space >>
          (str("sur le SI") >> space).maybe >>
          edition >> space >> version >> space >>
          str("(") >> years >> str(", ") >> lang >> str(")")).as(:si_brochure)
      end

      # --- SI Brochure appendices / derived products ---
      # Short docnumber forms used as the relaton index key (distinct from the
      # bespoke edition form above): an appendix, or the Concise / FAQ products.
      rule(:brochure_variant) do
        ((str("Appendix") >> space >> digits) | str("Concise") | str("FAQ"))
          .as(:variant)
      end
      rule(:si_brochure_variant) do
        (str("SI Brochure") >> space >> brochure_variant)
          .as(:si_brochure_variant)
      end

      # --- Mises en pratique (MEP) ---
      # Standard MEP code (unit letter(s) + number, or an alphabetic code), and
      # the "Rapport BIPM-YYYY/NN" report variant. Both index off the short
      # docnumber, not the long "Appendix 2 Part x" content string.
      rule(:mep_code) { match["0-9A-Za-z"].repeat(1).as(:mep_code) }
      rule(:report_code) do
        (str("BIPM-") >> digits >> str("/") >> digits).as(:report_code)
      end
      rule(:mep) do
        ((str("SI MEP") >> space >> mep_code) |
          (str("Rapport") >> space >> report_code)).as(:mep)
      end

      # --- Consultative-Committee guides ---
      # "<committee>-GD-<kind>-<number>", e.g. "CCL-GD-MeP-1", "CCEM-GD-RSI-1";
      # <kind> is "MeP" (mise en pratique) or "RSI" (réalisation du SI). Reuses
      # the shared `group` (committee) and `number` (trailing sequence).
      rule(:guide_kind) { (str("MeP") | str("RSI")).as(:guide_kind) }
      rule(:guide) do
        (group >> str("-GD-") >> guide_kind >> str("-") >>
          digits.as(:number)).as(:guide)
      end

      # After a leading group token, the shape after the first space decides:
      # a digit → meeting; a type word → committee.
      rule(:group_leading) do
        meeting_en | meeting_fr | committee_short | committee_long_en |
          committee_bare
      end

      rule(:identifier) do
        metrologia | si_brochure | si_brochure_variant | mep | guide |
          committee_long_fr | group_leading
      end

      root(:identifier)

      def self.parse(input)
        new.parse(input)
      end
    end
  end
end
