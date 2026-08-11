# frozen_string_literal: true

require "parslet"

module Pubid
  module Itu
    class Parser < Parslet::Parser
      # Basic elements
      rule(:digit) { match["0-9"] }
      rule(:digits) { digit.repeat(1) }
      rule(:letter) { match["A-Z"] }
      rule(:space) { str(" ") }
      rule(:dash) { str("-") }
      rule(:dot) { str(".") }

      # ITU prefix — accepts an optional leading "Recommendation " long-form
      # prefix that appears in ITU's own citation style (e.g. the twin-text
      # and common-text forms in issues #233 / #234).
      rule(:itu_prefix) do
        (str("Recommendation ") >> str("ITU") >> (dash | space)) |
          (str("ITU") >> (dash | space))
      end

      # Sector (R, T, or D)
      rule(:sector) do
        (str("R") | str("T") | str("D")).as(:sector)
      end

      # Series (BO, V, X, etc.)
      rule(:series) do
        (
          # Study groups: SG1, SG12
          (str("SG") >> digits) |
          # Regular series: BO, V, X, etc.
          letter.repeat(1, 3)
        ).as(:series)
      end

      # Number
      rule(:number) do
        digits.as(:number)
      end

      rule(:subseries) do
        dot >> digits.as(:subseries)
      end

      # Edition suffix attached directly to the recommendation number.
      # "bis" = 2nd edition, "ter" = 3rd, "quater" = 4th.
      # Example: X.50bis, V.8bis, V.31bis.
      rule(:series_suffix) do
        (str("bis") | str("ter") | str("quater")).as(:series_suffix)
      end

      # Parts
      rule(:part) do
        dash >> digits.as(:part)
      end

      rule(:parts) { part.repeat(0).as(:parts) }

      # Code = imp-prefixed code (Implementers' Guide) or standard code.
      # The imp_code alternative is tried first because the standard code's
      # number rule requires digits, which "Imp712" / "ImpOSI" would not
      # satisfy.
      rule(:code) do
        imp_code | standard_code
      end

      rule(:standard_code) do
        number >> series_suffix.maybe >> subseries.maybe >> parts
      end

      # Implementers' Guide code: "Imp" prefix followed by digits or a
      # short letter string. Examples: Imp712 (G.Imp712), ImpOSI (X.ImpOSI).
      rule(:imp_code) do
        str("Imp").as(:imp_marker) >>
          (digits | letter.repeat(1, 3)).as(:number) >>
          subseries.maybe >>
          parts
      end

      # Date
      rule(:date_part) do
        space >> str("(") >>
          (digits.as(:month) >> str("/")).maybe >>
          digit.repeat(4, 4).as(:year) >>
          str(")")
      end

      # Version marker — "(V14)" in "ITU-T H.264 (V14) (08/2021)". Always sits
      # between the code and the publication date, so it is spliced in before
      # `date_part.maybe` in every document rule. `date_part` requires digits
      # after "(", so it fails cleanly on "(V…)" and the two never compete.
      rule(:version_part) do
        space >> str("(V") >> digits.as(:version) >> str(")")
      end

      # Language
      rule(:language) do
        dash >> match["EFASCR"].as(:language)
      end

      # Combined (joint) recommendation — one additional "/SERIES.CODE"
      # designation, e.g. the "/Y.1351" of "G.780/Y.1351". Repeatable, so
      # triple-joint forms ("G.780/Y.1351/Z.1362") are captured as a list.
      # Each designation is a self-contained subtree under :designation; the
      # repeated list is collected under :combined.
      rule(:combined_designation) do
        str("/") >>
          (
            series >> dot >> digits.as(:number) >>
              subseries.maybe >> parts
          ).as(:designation)
      end

      rule(:combined_suffixes) do
        combined_designation.repeat(1).as(:combined)
      end

      # Supplement types
      rule(:supplement_type) do
        (
          str("Suppl.") | str("Suppl") |
          str("Amd.") | str("Amd") |
          str("Cor.") | str("Cor") |
          str("Err.") | str("Err")
        ).as(:supplement_type)
      end

      # Supplement number
      rule(:supplement_number) do
        space >> digits.as(:supplement_number)
      end

      # Supplement date (separate from base date)
      rule(:supplement_date) do
        space >> str("(") >>
          (digits.as(:supplement_month) >> str("/")).maybe >>
          digit.repeat(4, 4).as(:supplement_year) >>
          str(")")
      end

      # Base identifier for supplements
      rule(:base_with_series) do
        itu_prefix >>
          sector >>
          space >>
          series >> dot >>
          code >>
          combined_suffixes.maybe >>
          version_part.maybe >>
          date_part.maybe
      end

      rule(:base_without_series) do
        itu_prefix >>
          sector >>
          space >>
          code >>
          version_part.maybe >>
          date_part.maybe
      end

      rule(:base) do
        base_with_series | base_without_series
      end

      # Annex label — one series letter, optionally a number ("F3") and/or a
      # "+" ("C+", ITU-T G.729 Annex C+).
      rule(:annex_label) do
        letter >> digits.maybe >> str("+").maybe
      end

      # A labelled annex of a Recommendation — "ITU-T A.23 Annex A (06/2014)".
      # The annexed document is wrapped in :base so its own date (the leading
      # "(2002)" of "ITU-T X.692 (2002) Annex E (03/2002)") lands one level down
      # and cannot collide with the annex's date — Parslet silently keeps only
      # the last of two same-named keys in one flattened hash.
      rule(:annex_body) do
        base.as(:base) >>
          space >> str("Annex") >> space >>
          annex_label.as(:annex_number) >>
          date_part.maybe
      end

      rule(:annex_identifier) { annex_body >> language.maybe }

      # Supplement with base identifier (has recommendation number).
      # The base may itself be an annex ("... Annex B (1996) Cor. 3 (03/2001)");
      # annex_body is tried first because it is the longer match. When it fails
      # (an ordinary supplement, where " Suppl." follows the code instead of
      # " Annex") the alternation falls through to the plain base.
      rule(:supplement_with_base) do
        (annex_body.as(:base) | base.as(:base)) >>
          space >>
          supplement_type >>
          supplement_number >>
          supplement_date.maybe >>
          language.maybe
      end

      # A supplement whose base is itself a supplement — e.g. Errata on an
      # Amendment ("G.9701 (2014) Amd. 3 Err. 1 (12/2017)") or Errata on a
      # Corrigendum. The parse tree nests base-inside-base so the builder
      # produces a Supplement whose base is another Supplement.
      rule(:chained_supplement) do
        supplement_with_base.as(:base) >>
          space >>
          supplement_type >>
          supplement_number >>
          supplement_date.maybe >>
          language.maybe
      end

      # Supplement without base (series-only, like "ITU-T H Suppl. 1")
      rule(:supplement_series_only) do
        itu_prefix >>
          sector >>
          space >>
          series >>
          space >>
          supplement_type >>
          supplement_number >>
          supplement_date.maybe >>
          language.maybe
      end

      # Complete supplement identifier (try chained first, then with base, then series-only)
      rule(:supplement_identifier) do
        chained_supplement | supplement_with_base | supplement_series_only
      end

      # With series: ITU-R BO.600-1
      rule(:with_series) do
        itu_prefix >>
          sector >>
          space >>
          series >> dot >>
          code >>
          combined_suffixes.maybe >>
          version_part.maybe >>
          date_part.maybe >>
          language.maybe
      end

      # Without series: ITU-R 20-200
      rule(:without_series) do
        itu_prefix >>
          sector >>
          space >>
          code >>
          version_part.maybe >>
          date_part.maybe >>
          language.maybe
      end

      # OB (Operational Bulletin) — Special Publication.
      # OB is a cross-bureau ITU publication; sector, when present in legacy
      # strings like "ITU-T OB.1096", is silently dropped by the builder.
      rule(:ob_series) { str("OB").as(:series) }

      rule(:ob_dot_body) { dot >> number }
      rule(:ob_no_body) { space >> str("No.") >> space >> number }

      rule(:ob_with_sector) do
        itu_prefix >>
          (sector >> space).maybe >>
          ob_series >>
          (ob_dot_body | ob_no_body) >>
          date_part.maybe >>
          language.maybe
      end

      # Legacy long form: "ITU-T Operational Bulletin No. 1096".
      # The :_op_bull marker tells the builder to set series=OB.
      rule(:ob_long_form) do
        itu_prefix >>
          (sector >> space).maybe >>
          str("Operational Bulletin").as(:_op_bull) >>
          space >> str("No.") >> space >>
          number >>
          date_part.maybe >>
          language.maybe
      end

      rule(:special_publication) { ob_with_sector | ob_long_form }

      # "Annex to ..." — the document IS the annex of a Special Publication
      # (no annex number). The :annex_to wrapping signals to the builder.
      rule(:annex_to_identifier) do
        str("Annex to") >> space >> special_publication.as(:annex_to)
      end

      # Handbook — "ITU-R 42.HDB". The ".HDB" literal marks a Handbook; it does
      # NOT route through subseries (which is digits-only). The :handbook_marker
      # key tells the builder to build Identifiers::Handbook.
      rule(:handbook) do
        itu_prefix >>
          sector >>
          space >>
          number >>
          dot >> str("HDB").as(:handbook_marker) >>
          date_part.maybe
      end

      # Numeric Question — "ITU-R 234-1/7:", "ITU-R 237/3:".
      # number(-part)/study-group, always with a trailing ":".
      rule(:numeric_question) do
        itu_prefix >>
          sector >>
          space >>
          number >>
          parts >>
          str("/") >> digits.as(:study_group) >>
          str(":").as(:question_colon).maybe
      end

      # One "number(/BL)?/study-group" body of a letter-series Question, shared
      # by the bracketed and bare forms.
      rule(:question_tail) do
        number >>
          str("/BL").as(:has_bl).maybe >>
          str("/") >> digits.as(:study_group)
      end

      # Letter-series Question — "ITU-R P.3/BL/7", "ITU-R SM.1/30",
      # "ITU-R S.[4/BL/2]:". series.number(/BL)?/study-group, optionally
      # bracketed and/or with a trailing ":".
      rule(:letter_question) do
        itu_prefix >>
          sector >>
          space >>
          series >> dot >>
          (
            (str("[").as(:bracketed) >> question_tail >> str("]")) |
            question_tail
          ) >>
          str(":").as(:question_colon).maybe
      end

      # Common-text suffix: "| ISO/IEC ..." or "| ISO ..." — the same
      # document published jointly by ITU and ISO/IEC. Captured as a raw
      # string; the builder parses it with the appropriate flavor.
      rule(:common_text_twin) do
        (space >> str("|") >> space >> match("[^|]").repeat(1)).as(:common_text_twin)
      end

      rule(:identifier) do
        annex_to_identifier |
          special_publication |
          supplement_identifier |
          # Both neighbours are load-bearing (PEG ordered choice never re-enters
          # the alternation once an alternative succeeds): AFTER
          # supplement_identifier, which matches the longer "<annex> Cor. 3"
          # form, and BEFORE with_series, which would match the "ITU-T A.23"
          # prefix of "ITU-T A.23 Annex A" and then fail on the unconsumed tail.
          annex_identifier |
          handbook |
          numeric_question |
          letter_question |
          with_series |
          without_series
      end

      # Common-text form: an ITU identifier followed by "| ISO/IEC ...".
      # Tried last so it doesn't shadow the simpler single-identifier forms.
      rule(:common_text_identifier) do
        identifier >> common_text_twin
      end

      rule(:root) { common_text_identifier | identifier }

      def self.parse(input)
        new.parse(input)
      end
    end
  end
end
