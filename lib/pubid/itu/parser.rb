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

      # A numeric series GROUP rather than a single document — "E-100",
      # "E100-300", "G-100", "Q-500". Deliberately capped at ONE leading
      # letter: two or more letters before the dash is a series-code DOCUMENT
      # (EMC-5, MES-2, IMPL-8, SEC-QKD), handled by series_code_body, and the
      # two must never shadow each other. That split is a corpus regularity,
      # not an ITU rule — see the boundary spec.
      rule(:series_group) do
        (letter >> digits.maybe >> dash >> digits).as(:series)
      end

      # The literal word "series" — "ITU-T E-300 series Suppl. 1",
      # "ITU-T E.1100 series Suppl. 1". It is NOT part of the series token (it
      # also follows a dotted code, where folding it in would corrupt the value
      # every index row is keyed on), so it is carried as its own marker.
      rule(:series_word) { space >> str("series").as(:series_word) }

      # Number
      rule(:number) do
        digits.as(:number)
      end

      rule(:subseries) do
        dot >> digits.as(:subseries)
      end

      # Edition words. "bis" = 2nd edition, "ter" = 3rd, "quater" = 4th.
      # "quarter" is a real misspelling in ITU's own data, kept verbatim so the
      # two records it appears on stay distinct from their "quater" siblings.
      rule(:series_suffix_word) do
        str("bis") | str("ter") | str("quater") | str("quarter")
      end

      # Edition suffix attached directly to the recommendation number.
      # Example: X.50bis, V.8bis, V.31bis.
      rule(:series_suffix) { series_suffix_word.as(:series_suffix) }

      # The same word separated by a space — "ITU-T E.250 bis (12/1972)",
      # "ITU-T V.25 ter". The captured space IS the marker: its presence sets
      # Code#series_suffix_spaced, so the glued form above still round-trips
      # byte-exactly (locked by recommendation_spec.rb's issue-#231 block).
      rule(:series_suffix_spaced) do
        space.as(:series_suffix_spaced) >> series_suffix_word.as(:series_suffix)
      end

      # A single trailing letter distinguishing variants of one Recommendation:
      # "ITU-T D.200 R", "ITU-T Q.2931 B", "ITU-T R.38 A", the glued
      # "ITU-T D.502R" and the lowercase "ITU-T I.256.2a".
      #
      # TWO guards make this safe, and both are load-bearing:
      #   * the A-R cap keeps it clear of the "S" of " Suppl." and the "V" of a
      #     bare version marker (" V2");
      #   * the trailing absent? forbids any further letter/digit, so " Amd."
      #     (A then "m"), " Add.", " Annex A" (A then "n"), " App." , " Cor."
      #     (C then "o") and " Err." (E then "r") can never be mistaken for a
      #     qualifier.
      # It cannot collide with `language` (dash-attached, "-F") nor with
      # date_part/version_part, which both need "(" after the space.
      rule(:qualifier_letter) do
        (match["A-R"] | match["a-r"]).as(:qualifier) >>
          match["A-Za-z0-9"].absent?
      end

      rule(:qualifier_glued) { qualifier_letter }
      rule(:qualifier_spaced) do
        space.as(:qualifier_spaced) >> qualifier_letter
      end

      # Print-form suffixes that may trail a code with a separating space. They
      # cannot live inside `code` itself, because the space would then also be
      # offered to " Suppl." / " Annex" and would have to backtrack out of a
      # rule the wrappers depend on. Spliced after `code` and BEFORE
      # combined_suffixes, since the corpus attaches the primary designation's
      # suffix before the "/" ("ITU-T D.301 R/F.66").
      rule(:code_suffixes) do
        series_suffix_spaced.maybe >> qualifier_spaced.maybe
      end

      # "ITU-T H.350 attachment (08/2003)" — the machine-readable attachment
      # published alongside a Recommendation, a distinct record in ITU's
      # catalogue. A bare marker word: the flag alone reconstructs it.
      rule(:attachment) { space >> str("attachment").as(:attachment) }

      # A range of Recommendations published as one document —
      # "ITU-T Q.120-Q.139 (11/1988)". No conflict with `parts`, which requires
      # digits after the dash and so cannot match "-Q.139".
      rule(:range_end) do
        dash >> (letter.repeat(1, 3) >> dot >> digits).as(:range_end)
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

      # The glued qualifier sits last, after parts, so "BO.600-1" still parses
      # and "D.502R" / "I.256.2a" newly do.
      rule(:standard_code) do
        number >> series_suffix.maybe >> subseries.maybe >> parts >>
          qualifier_glued.maybe
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
      # ITU emits four spellings of the same marker: the canonical
      # parenthesised "(V14)" plus the bare "V2", "v10" and "v.1". All land in
      # the same `version` attribute and re-render canonically as " (V##)" —
      # the one deliberate non-byte-exact normalisation in this grammar.
      #
      # The bare branch requires digits immediately after V/v so it cannot fire
      # on a stray word, and it is unreachable by the qualifier_letter rule
      # below, whose A-R cap deliberately excludes "V".
      rule(:version_part) do
        space >>
          (
            (str("(V") >> digits.as(:version) >> str(")")) |
            ((str("V") | str("v")) >> dot.maybe >> digits.as(:version))
          )
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
      # A designation may carry the same print-form suffixes as the primary
      # code — "ITU-T D.300 R/E.282 R" (both halves qualified),
      # "ITU-T D.81/F.80 bis" and "ITU-T E.211/Q.11 quater" (only the last).
      # The suffix is stored on the designation it printed against; no attempt
      # is made to decide whether it semantically qualifies the joint document.
      #
      # These slots sit INSIDE the .as(:designation) subtree, so they consume
      # " bis" before the outer code_suffixes (which precedes combined_suffixes)
      # can see it — that is what makes "trails the last designation" work
      # without ambiguity.
      rule(:combined_designation) do
        str("/") >>
          (
            series >> dot >> digits.as(:number) >>
              subseries.maybe >> parts >>
              qualifier_glued.maybe >>
              series_suffix_spaced.maybe >>
              qualifier_spaced.maybe
          ).as(:designation)
      end

      rule(:combined_suffixes) do
        combined_designation.repeat(1).as(:combined)
      end

      # The "Technical" qualifier of a Corrigendum — "ITU-T H.222.0 (1995)
      # Technical Cor. 1 (02/1998)". It is captured as its OWN marker key
      # rather than folded into the supplement_type alternation, so the type
      # token stays the plain "Cor." that Builder#build_supplement's case maps.
      # It is bound to the Cor. branch alone, NOT to the head of
      # supplement_type: only a corrigendum is ever printed "Technical", and
      # only Corrigendum carries the flag. Offered before any token, the
      # marker would be accepted on "Technical Err. 1" / "Technical Amd. 1"
      # and then silently dropped by the builder, collapsing those onto a
      # different document's identifier.
      rule(:technical_marker) do
        str("Technical").as(:technical) >> space
      end

      # Supplement types. The Cor. branch is its own alternative so the
      # optional "Technical" can precede it without landing inside the
      # .as(:supplement_type) capture — the builder maps that token by string
      # equality. It goes last, which is free: no other branch can match a
      # leading "Technical" or "Cor".
      rule(:supplement_type) do
        (
          str("Suppl.") | str("Suppl") |
          str("Amd.") | str("Amd") |
          str("Add.") | str("Add") |
          str("Err.") | str("Err")
        ).as(:supplement_type) |
          (technical_marker.maybe >>
            (str("Cor.") | str("Cor")).as(:supplement_type))
      end

      # Supplement number. ITU omits the space before the ordinal on some
      # listings ("ITU-T E Suppl.1", "ITU-T D.211 Suppl.1") and the ordinal is
      # itself dotted on the M/O series ("ITU-T M Suppl. 1.1"). The absent
      # space is captured as a marker so `to_s` reproduces it; the dotted
      # ordinal lands whole in the :string `number` and cannot run into a
      # following date, because (dot >> digits) stops at the space before "(".
      rule(:supplement_number) do
        space.as(:supplement_space).maybe >>
          (digits >> (dot >> digits).repeat(0)).as(:supplement_number)
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
          range_end.maybe >>
          code_suffixes >>
          combined_suffixes.maybe >>
          series_word.maybe >>
          attachment.maybe >>
          version_part.maybe >>
          date_part.maybe
      end

      rule(:base_without_series) do
        itu_prefix >>
          sector >>
          space >>
          code >>
          code_suffixes >>
          attachment.maybe >>
          version_part.maybe >>
          date_part.maybe
      end

      # A series-code document — "EMC-5", "MES-2", "QOS-2", "IMPL-8",
      # "SEC-QKD": a multi-letter mnemonic series dash-joined to a numeric or
      # alphabetic document code. TWO letters minimum is the discriminator
      # against series_group ("E-100", "G-100"), which has exactly one.
      #
      # This rule carries its own letter repeat, so the 1..3 cap on `series`
      # (which stops the series token eating a following word) is untouched
      # and "IMPL" still parses. It is deliberately a flat two-token shape
      # (series + dash + alphanumeric number) rather than an optional middle
      # segment: a greedy `letter.repeat(2)` would take "SEC", an optional
      # "-QKD" would follow, and the required dash would then fail at
      # end-of-input with no backtracking into the satisfied `.maybe`.
      #
      # The number stays in `code.number`, so `root.number` — the field
      # relaton-index bsearches on — is "5" for EMC-5 and "QKD" for SEC-QKD
      # rather than nil.
      # The OB guard keeps "ITU-T OB-1" a clean parse failure. Without it the
      # string reaches Builder#build's Recommendation fallback, whose
      # validate_ob_no_sector! raises an ArgumentError that escapes
      # Identifier.parse's Parslet::ParseFailed rescue — turning a rejected
      # input into a crash for callers. It guards "OB" + dash specifically, so
      # a genuine two-letter mnemonic starting "OB" would still parse.
      rule(:series_code_body) do
        (str("OB") >> dash).absent? >>
          letter.repeat(2).as(:series) >> dash.as(:series_dash) >>
          (digits | letter.repeat(1)).as(:number) >> parts
      end

      rule(:base_series_code) do
        itu_prefix >>
          sector >>
          space >>
          series_code_body >>
          version_part.maybe >>
          date_part.maybe
      end

      rule(:series_code_identifier) { base_series_code >> language.maybe }

      # base_series_code goes LAST: it cannot shadow base_with_series (which
      # needs series >> dot — "EMC" then "." fails on "-", and the greedy
      # "IMP" of "IMPL" then fails on "L") nor base_without_series (whose code
      # needs digits or "Imp"), so the last slot is both safe and the smallest
      # blast radius.
      rule(:base) do
        base_with_series | base_without_series | base_series_code
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

      # Appendix label — a Roman numeral ("I", "II", "IV", "VI").
      rule(:roman) { match["IVX"].repeat(1) }

      # A labelled appendix of a Recommendation — "ITU-T G.101 App. I
      # (05/2000)", "ITU-T O.9 App.I (1998)". Structurally identical to
      # annex_body, and for the same reason: the appendixed document is wrapped
      # in :base so its own date (the leading "(1988)" of "ITU-T G.722 (1988)
      # App. IV (11/2006)") lands one level down and cannot collide with the
      # appendix's — Parslet silently keeps only the last of two same-named
      # keys in one flattened hash. The space after "App." is optional in ITU's
      # listings; rendering normalises it back to the spaced spelling.
      rule(:appendix_body) do
        base.as(:base) >>
          space >> str("App.") >> space.maybe >>
          roman.as(:appendix_number) >>
          appendix_material.maybe >>
          date_part.maybe
      end

      # The companion artefact of an appendix, published as its own record —
      # "ITU-T G.726 App. II test vectors (03/1991)",
      # "ITU-T G.728 App. I Software (07/1995)". A closed set of two literals,
      # not free text, so it cannot swallow an unrelated tail.
      rule(:appendix_material) do
        space >> (str("test vectors") | str("Software")).as(:appendix_material)
      end

      rule(:appendix_identifier) { appendix_body >> language.maybe }

      # Supplement with base identifier (has recommendation number).
      # The base may itself be an annex ("... Annex B (1996) Cor. 3 (03/2001)");
      # annex_body is tried first because it is the longer match. When it fails
      # (an ordinary supplement, where " Suppl." follows the code instead of
      # " Annex") the alternation falls through to the plain base.
      rule(:supplement_with_base) do
        (annex_body.as(:base) | appendix_body.as(:base) | base.as(:base)) >>
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
      # The inner supplement may itself be the base-less, series-only form —
      # "ITU-T G Suppl. 39 (2006) Err. 1 (08/2006)". supplement_with_base is
      # tried first, being the longer match.
      rule(:chained_supplement) do
        (supplement_with_base | supplement_series_only).as(:base) >>
          space >>
          supplement_type >>
          supplement_number >>
          supplement_date.maybe >>
          language.maybe
      end

      # Supplement without base (series-only, like "ITU-T H Suppl. 1")
      # series_group is tried FIRST: `series` is a greedy, non-backtracking
      # letter.repeat(1,3), so it would match the "E" of "E-100" and then fail
      # on the required space, with no retry at a shorter length.
      rule(:supplement_series_only) do
        itu_prefix >>
          sector >>
          space >>
          (series_group | series) >>
          series_word.maybe >>
          space >>
          supplement_type >>
          supplement_number >>
          supplement_date.maybe >>
          language.maybe
      end

      # A supplement joined to its predecessor by "/" rather than a space —
      # "ITU-T X.680 (1994) Amd. 1/Technical Cor. 1 (12/1997)": one Technical
      # Corrigendum issued against Amendment 1, sharing the trailing date.
      # Modelled exactly like chained_supplement (base-inside-base) with a
      # :supplement_slash marker so `to_s` reproduces the "/".
      rule(:slash_chained_supplement) do
        supplement_with_base.as(:base) >>
          str("/").as(:supplement_slash) >>
          supplement_type >>
          supplement_number >>
          supplement_date.maybe >>
          language.maybe
      end

      # Complete supplement identifier. Both chained forms must precede
      # supplement_with_base: it alone matches "ITU-T X.680 (1994) Amd. 1" and
      # would leave "/Technical Cor. 1 (12/1997)" unconsumed, which fails the
      # whole parse — PEG ordered choice never re-enters the alternation once
      # an alternative succeeds. Space- and slash-joined are disjoint at that
      # position, so their relative order is free.
      rule(:supplement_identifier) do
        chained_supplement | slash_chained_supplement |
          supplement_with_base | supplement_series_only
      end

      # With series: ITU-R BO.600-1
      rule(:with_series) do
        itu_prefix >>
          sector >>
          space >>
          series >> dot >>
          code >>
          range_end.maybe >>
          code_suffixes >>
          combined_suffixes.maybe >>
          series_word.maybe >>
          attachment.maybe >>
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
          code_suffixes >>
          attachment.maybe >>
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
          # Same slot reasoning as annex_identifier: AFTER supplement_identifier
          # (an appendix can carry a trailing Amd./Err.) and BEFORE with_series
          # (which would match the "ITU-T G.101" prefix and then fail on the
          # unconsumed " App. I").
          appendix_identifier |
          handbook |
          numeric_question |
          letter_question |
          with_series |
          # Unreachable earlier: special_publication needs the literal "OB",
          # handbook/numeric_question need leading digits, and letter_question
          # needs series >> dot. Before without_series, whose code needs digits.
          series_code_identifier |
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
