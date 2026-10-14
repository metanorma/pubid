# frozen_string_literal: true

require "parslet"

module Pubid
  module Ieee
    # Parser class for IEEE identifiers
    # Single Responsibility: Parsing IEEE identifier syntax
    # Note: IEEE is extremely complex with many edge cases
    class Parser < ::Pubid::Parser::Grammar
      # Basic building blocks
      rule(:space) { str(" ") }
      rule(:space?) { space.maybe }
      rule(:dash) { str("-") }
      rule(:dash?) { dash.maybe }
      rule(:dot) { str(".") }
      rule(:slash) { str("/") }
      rule(:comma) { str(", ") }
      rule(:digit) { match("[0-9]") }
      rule(:digits) { digit.repeat(1) }
      rule(:letter) { match("[A-Za-z]") }
      rule(:upper) { match("[A-Z]") }
      rule(:lower) { match("[a-z]") }

      # Year pattern (4 digits starting with 19 or 20), optionally followed by letter(s)
      # e.g. 2012, 201x, 2010a
      rule(:year_digits) do
        (str("19") | str("20")) >> digit.repeat(2,
                                                2) >> lower.repeat(0,
                                                                   2) >> digits.absent?
      end

      # Month patterns - numeric format (01-12)
      rule(:month_numeric) do
        (str("0") >> match("[1-9]")) | # 01-09
          (str("1") >> match("[0-2]")) # 10-12
      end

      # Comprehensive date parsing
      # Format 1: "September 2018" or "Sept 2018" (text month + year)
      rule(:date_with_month_text) do
        month_name.as(:month) >> space >> year_digits.as(:year)
      end

      # Format 2: "2018-09" (year-numeric month)
      rule(:date_with_month_numeric) do
        year_digits.as(:year) >> dash >> month_numeric.as(:month)
      end

      # Format 3: Just year "2018"
      rule(:date_year_only) do
        year_digits.as(:year)
      end

      # Combined date rule - longest match first
      rule(:date_standalone) do
        date_with_month_text | date_with_month_numeric | date_year_only
      end

      # Trailing print/reaffirm date "<sep>Month YYYY" — captured under the
      # distinct :trailing_month/:trailing_year keys so it never collides with a
      # base -YYYY identity year (the builder promotes it only when no base year
      # exists). Accepts BOTH a month name ("May 2014") and a month-first numeric
      # month ("05 2014"). The two variants are unambiguous: month_name never
      # starts with a digit, and month_numeric (01-12) never matches a bare
      # 19xx/20xx year — so a bare trailing year still falls through to callers'
      # own bare-year clause.
      rule(:trailing_month_year) do
        # The numeric branch accepts `-` as well as space before the year:
        # preprocessing (the `(\d)\s+(\d{4})` gsub) rewrites a trailing
        # "05 2014" → "05-2014", so a numeric month reaches the grammar
        # dash-joined; the month-name branch escapes that gsub (the char before
        # the space is a letter) and stays space-joined.
        ((comma | space) >> month_name.as(:trailing_month) >> space >> year_digits.as(:trailing_year)) |
          ((comma | space) >> month_numeric.as(:trailing_month) >> (space | dash) >> year_digits.as(:trailing_year))
      end

      # Month patterns
      rule(:month_name) do
        # Period-suffixed abbreviations (longest first)
        str("Sept.") | str("Oct.") | str("Nov.") | str("Dec.") |
          str("Jan.") | str("Feb.") | str("Mar.") | str("Apr.") |
          str("Jun.") | str("Jul.") | str("Aug.") |
          # Full month names
          str("January") | str("February") | str("March") | str("April") |
          str("May") | str("June") | str("July") | str("August") |
          str("September") | str("October") | str("November") | str("December") |
          # Non-period abbreviations
          str("Jan") | str("Feb") | str("Mar") | str("Apr") | str("Jun") |
          str("Jul") | str("Aug") | str("Sep") | str("Sept") | str("Oct") | str("Nov") | str("Dec")
      end

      # Organizations
      rule(:organization) do
        str("IEEE") | str("AIEE") | str("ANSI") | str("ASA") |
          # ANS (American Nuclear Society) — a third co-publisher on nuclear
          # standards ("ANSI/IEEE/ANS 7.4-3-2-1982"). Listed AFTER ANSI so it
          # never shadows the longer token.
          str("ANS") |
          str("IEC") | str("ISO") | str("ASTM") | str("CSA") | str("ASME") |
          str("NACE") | str("NSF") | str("ASHRAE") | str("NCTA") | str("AESC") |
          str("EIA") | # NEW Session 224: Add EIA support
          # Historical / foreign co-publishers seen in relaton-data-ieee
          # (bucket 4): AMPP, USAS (both standalone), and the IEEE sub-board /
          # partner co-publishers USEMCSC, EAB, MPAI.
          str("USEMCSC") | str("AMPP") | str("USAS") | str("EAB") | str("MPAI")
      end

      # Complex organization prefixes (Category 5: ANSI Complex)
      rule(:complex_org_prefix) do
        str("ANSI/IEEE-ANS") | str("ANSI/IEEE") | str("ANSI")
      end

      # Characteristic IEEE number patterns (without prefix)
      # These patterns are distinctly IEEE even without "IEEE Std" prefix
      rule(:characteristic_ieee_number) do
        # C37.xxx series (power systems) - C followed by 2 digits, dot, more digits
        (str("C") >> digit.repeat(2,
                                  2) >> dot >> digits >> match("[a-z]").repeat.maybe) |
          # 802.xxx series (networking) - 802 followed by dot, digits, optional letter suffix
          (str("802") >> dot >> digits >> match("[a-z]").repeat.maybe) |
          # P followed by digits (draft projects)
          (str("P") >> digits.repeat(1))
      end

      rule(:publisher) do
        complex_org_prefix.as(:publisher) | organization.as(:publisher)
      end

      rule(:copublisher) do
        # Three-way copublisher strings (treat as single unit, longest first)
        str("/ISO/IEC").as(:copublisher) |
          str("/IEC/ISO").as(:copublisher) |
          # Two-way copublishers (original pattern)
          (slash >> space? >> organization.as(:copublisher))
      end

      # Conformance document patterns (/Conformance01-2003, /Conformance02-2014)
      # Allow optional space before slash for malformed inputs
      rule(:conformance) do
        (space? >> slash >> str("Conformance") >> match("[0-9]").repeat(1).as(:conf_number) >> dash >> year_digits.as(:conf_year)).as(:conformance)
      end

      # ASHRAE joint publication patterns (/ASHRAE Guideline 21-2012)
      # Also handles /ASHRAE 21 without "Guideline"
      rule(:ashrae_copub) do
        (slash >> str("ASHRAE") >> space >>
         (str("Guideline") >> space).maybe >>
         digits.as(:ashrae_number) >>
         (dash >> year_digits.as(:ashrae_year)).maybe).as(:ashrae_copub)
      end

      # IEEE cross-reference patterns (/C62.22.1-1996)
      # References another IEEE standard from a specific series (e.g., C62, C37, C57)
      rule(:ieee_crossref) do
        (slash >> str("C") >> digits >> dot >> digits >> dot >> digits >> dash >> year_digits).as(:ieee_crossref)
      end

      # IPCEA co-designation suffix (/IPCEA P-46-426-1962). Captured verbatim
      # (leading slash included) so it round-trips through the `crossref`
      # attribute. Used only by the S-designation rule below.
      rule(:ipcea_copub) do
        (slash >> str("IPCEA") >> space >>
         match('[A-Za-z0-9.\-]').repeat(1)).as(:ipcea_copub)
      end

      # Historical IEEE/IPCEA co-published cable designation (e.g. S-135).
      # The "S-<digits>" number has a dash between the letter series and the
      # digits, which the shared `number` rule deliberately rejects (that
      # tightening is what keeps a bare "IEEE S" from parsing). So this one-off
      # family gets its own rule rather than loosening `number` and risking the
      # 12k-row corpus. Requiring `str("S") >> dash >> digits` keeps "IEEE S"
      # (no dash+digit) rejected. Handles: "IEEE Std S-135", "IEEE S-135",
      # bare "S-135", the "/IPCEA …" slash co-designation, and the
      # "(IPCEA …)" parenthetical variant.
      rule(:s_designation) do
        (publisher >> space).maybe >>
          (type_word.as(:type) >> space?).maybe >>
          (str("S") >> dash >> digits).as(:s_number) >>
          ipcea_copub.maybe >>
          parenthetical.maybe
      end

      # Document number - support letters and digits, with optional prefix P
      # Complex multi-part numbers like P11073-10404-10419 should be fully captured
      # But simple cases like "623-1976" should not consume the dash before year
      rule(:number) do
        (str("P").maybe >>
         # The numeric core must contain at least one digit: an optional letter
         # prefix (C, S, …) then a required `digits` run, then any digit/letter
         # tail. The old `(digits | upper).repeat(1)` wrongly accepted an
         # all-letter token like a bare "S" (a prefix with no number — e.g.
         # "IEEE S"), which is not a valid IEEE identifier.
         upper.repeat(0) >> digits >> (digits | upper).repeat(0) >>
         # Only consume dash+digits if followed by another dash+digits (multi-part pattern)
         # OR if the digits don't look like a year (not 4 digits starting with 19/20)
         # This prevents consuming "623-1976" as a number but allows "P11073-10404-10419"
         (dash >> digits >> year_digits.absent? >> (dash >> digits).repeat).maybe >>
         lower.maybe).as(:number)
      end

      # Type - handle "No." and "No" (case-insensitive), longest first
      rule(:type_word) do
        str("Draft Std") | str("STD") | str("Standard") |
          str("Std No.") | str("Std") | # Add "Std No." before "Std"
          str("PTC") | # ASME Performance Test Code
          (match("[Nn]") >> str("o.")) | (match("[Nn]") >> str("o")) |
          str("No")
      end

      # Part and subpart - handle both dot and dash separators
      rule(:part) do
        (dot | dash) >> match("[0-9A-Za-z]").repeat(1).as(:part)
      end

      rule(:subpart) do
        (dot | dash | str("_")) >>
          ((str("REV") | str("Rev")).maybe >> match("[0-9a-z]").repeat(1) >>
           (dot >> digits).maybe).as(:subpart)
      end

      # Year component - updated to use comprehensive date parsing
      rule(:year) do
        (dot | dash) >> date_standalone >> str("(E)").maybe
      end

      # Draft patterns
      rule(:draft_status) do
        # "Active" (bucket 3) joins the generic draft-status path so
        # "IEEE Active Std P… /D…" parses like the "Unapproved" forms, without
        # touching ieee_approved_draft_identifier (which would break the
        # issue-#209 unapproved-drops-Std rendering). "Active Approved" completes
        # the two-word matrix alongside "Active Unapproved" (draft-grammar
        # coverage: the "<status> Draft P…/D…" prefix forms). Longest token first.
        (str("Active Unapproved") | str("Active Approved") | str("Unapproved") |
         str("Approved") | str("Active")) >> space
      end

      rule(:draft_prefix) do
        space? >> (str("/") | str("_") | dash | space)
      end

      rule(:draft_version) do
        # Enhanced to handle multiple draft notation patterns
        # D is optional to handle /08 style drafts (e.g., IEEE P1052/08)
        # A draft never begins with "R-" — that is the revision suffix
        # (revision_suffix rule); guard so the D-less path doesn't swallow a
        # bare "/R-<id>" (e.g. the no-draft "P1722/R-1") as a draft.
        (str("R") >> dash).absent? >>
          (str("D") >> str("IS").absent?).maybe >> # Avoid matching "DIS" (ISO stage)
          (
            # Pattern: D3.1 (decimal with 1-2 digits on each side) - MOST COMMON, put first
            # Also handles trailing letter: D7.3A, D2.0E
            (match("[0-9]").repeat(1,
                                   2) >> dot >> match("[0-9]").repeat(1,
                                                                      2) >> lower.maybe) |
            # Pattern: D.XX (decimal starting with dot) - e.g., D.19
            (dot >> digits) |
            # Pattern: DX+X (plus sign) - e.g., D1+1
            (digits >> str("+") >> digits) |
            # Pattern: DXXXXeYY or DXXXX.eYY (complex) - e.g., D2012.e27
            (digits >> dot.maybe >> str("e") >> digits) |
            # Pattern: D-X or DX or DX-d or DX_letter (original patterns)
            # Handles: D12, D3.0, D043Rev18, suffixes like D15Sept
            (str("-").maybe >> match("[0-9A-Za-z]").repeat(1) >> (str("-d") | (str("_") >> match("[0-9A-Za-z]").repeat(0))).maybe)
          ).as(:draft_version)
      end

      rule(:draft_date) do
        # Enhanced to handle: ", Sept 2008" or " Sept 2008" or ", Month Year"
        ((comma | space) >> month_name.as(:month) >> space >> year_digits.as(:year)) |
          # Space-separated bare year after the draft designator
          # ("IEEE Draft Std P14764/D1 2004, Nov 2004" - the "D1 2004" draft
          # carries its own year, with the print date still trailing).
          (space >> year_digits.as(:year)) |
          # Numeric-month form ", 05 2007" / " 05 2007" — no text month name. The
          # year separator may be a dash: preprocessing (parser.rb ~1278) rewrites
          # a trailing " <digits> <year>" to "<digits>-<year>", so "05 2007"
          # reaches the grammar as "05-2007".
          ((comma | space) >> month_numeric.as(:month) >> (space | dash) >> year_digits.as(:year)) |
          (((space? >> comma >> space?) | space) >> month_name.as(:month) >>
          (
            # "Month DD, Year" (day then comma) and "Month DD Year" (day, no
            # comma) — the day/year separator may be a dash for the same
            # preprocessing reason ("July 15 2012" → "July 15-2012").
            ((space >> digits.as(:day)) >> ((comma | space | dash) >> year_digits.as(:year))) |
            ((space >> digits.as(:day)).maybe >> comma >> year_digits.as(:year)) |
            (comma >> space? >> year_digits.as(:year)) |
            (space >> year_digits.as(:year))
          ))
      end

      # FDIS and similar ISO stage codes without D prefix (Pattern 3)
      # These appear after / in IEEE P identifiers but don't have the D prefix
      # Examples: IEEE P15939/FDIS, IEEE P1234/CDV
      rule(:fdraft) do
        (slash >>
         (str("FDIS") | str("CDV") | str("CD") | str("WD") | str("PWI") | str("NP")) >>
         (
           ((comma | space) >> month_name.as(:month) >> space >> year_digits.as(:year)) | # Month Year
           ((comma | space) >> year_digits.as(:year)) # Year only (e.g., /FDIS, 2016)
         ).maybe >>
         parenthetical.maybe).as(:fdraft)
      end

      rule(:draft) do
        (draft_prefix >> draft_version.repeat(1, 2) >>
         (dot >> digits.as(:revision)).maybe >>
         # The compound both-systems form (docs/IEEE-DRAFT-STAGES.md
         # §1.3): "=DDIS.3" - IEEE draft ordinal = draft of the ISO/IEC
         # stage, with its iteration. The glued "=DDIS3" / "=DDIS-3"
         # spellings are accepted aliases of "=DDIS.3".
         (str("=") >> (str("D") >> (str("FDIS") | str("CDV") | str("PWI") |
            str("DIS") | str("WD") | str("NP") | str("CD")) |
           (str("FDIS") | str("CDV") | str("PWI") | str("DIS") | str("WD") |
            str("NP") | str("CD"))).as(:draft_iso_stage) >>
           (dot | dash).maybe >> digits.as(:draft_iso_iteration).maybe).maybe >>
         draft_date.maybe).as(:draft)
      end

      # Trailing revision suffix "/R-<id>". Normalization funnels every revision
      # spelling here — IEEE's native inline "Rev<n>" (repositioned) and
      # relaton's synthetic "/R-<x>" (kept in place) — so a single trailing rule
      # captures them all. The id is alphanumeric ("2", "18", "i").
      rule(:revision_suffix) do
        slash >> str("R") >> dash >> match('[0-9A-Za-z]').repeat(1).as(:revision)
      end

      # Edition - enhanced to support IEC formats like "Edition 1.0 2015-03"
      #
      # The edition's own year is captured as :edition_year (NOT :year). The
      # generic Std branch carries a base "-YYYY" slot AND a separate trailing
      # `edition.maybe`; a bare :year here would collide with the base :year
      # when both fire, so Parslet warns "Duplicate subtrees … keys: [:year]"
      # and drops the base identity year (the same failure #299 fixed for the
      # trailing month/year clause). The builder promotes :edition_year to the
      # identity year only when there is no base year.
      rule(:edition) do
        (comma >> year_digits.as(:edition_year) >> str(" Edition")) |
          ((space | dash) >> str("Edition ") >>
           (digits >> dot >> digits).as(:edition) >>
           # Year separator: a space, " - ", or a bare dash (preprocessing
           # rewrites "Edition 3.0 2016" -> "Edition 3.0-2016", the shape the
           # normalized "/E-<n>-YYYY" suffix produces — nil-residue item 1).
           (str(" - ") | space | dash) >>
           year_digits.as(:edition_year) >>
           (dash >> digit.repeat(2, 2).as(:edition_month)).maybe) # Capture -MM as edition_month
      end

      # Part/subpart/year combinations
      rule(:part_subpart_year) do
        (part >> subpart.repeat(1, 2) >> year) |
          (part >> subpart >> year) |
          (part >> year) |
          (part >> subpart) |
          year |
          part
      end

      # Corrigendum
      rule(:corrigendum) do
        # Enhanced: Accept space as separator, make separators more flexible
        # Also accept "Corrigendum" as alternative to "Cor"
        ((str("_") | slash | dash | space) >>
         (str("Corrigendum") | str("Cor")) >>
         (dash | dot | space).maybe >> # More flexible separator after "Cor"
         space? >> # Add space handling after separator
         digits.as(:cor_number).maybe >>
         ((dash | str(":") | space) >> year_digits.as(:cor_year)).maybe).as(:corrigendum)
      end

      # Amendment — mirrors the corrigendum rule's separator flexibility so
      # IEEE-format "/Amd 2-2004" and "/Amd2-2004" parse the same way as
      # their Cor counterparts (issue #210).
      rule(:amendment) do
        ((str("_") | slash | dash | space) >>
         (str("Amendment") | str("Amd")) >>
         (dash | dot | space).maybe >>
         space? >>
         digits.as(:amd_number).maybe >>
         ((dash | str(":") | space) >> year_digits.as(:amd_year)).maybe).as(:amendment)
      end

      # Interpretation notation (/INT)
      # Enhanced to support optional year suffix: /INT-1991, /INT 1991
      rule(:interpretation) do
        (slash >> str("INT") >> ((dash | str(":") | space) >> year_digits.as(:int_year)).maybe).as(:interpretation)
      end

      # Reaffirmed - enhanced to support (R1992) format without space
      rule(:reaffirmed) do
        (
          # Format: "Reaffirmed 1992"
          (str("Reaffirmed ") >> year_digits.as(:year)) |
          # Format: "(R1992)" - parentheses with R prefix (with or without space before)
          (space.maybe >> str("(R") >> year_digits.as(:year) >> str(")"))
        ).as(:reaffirmed)
      end

      # Redline suffix at the very end. Accepts relaton's canonical " Redline"
      # (space, no dash) and pubid's older " - Redline" (space-dash-space),
      # case-insensitive. Captured (presence only) so the builder sets a
      # `redline: true` flag the renderer restores — a redline is a distinct
      # document and must not collapse to its base standard.
      rule(:redline) do
        (space >> (dash >> space).maybe >>
         (str("Redline") | str("REDLINE") | str("redline"))).as(:redline)
      end

      # Book nickname (e.g., "[The Orange Book]", "[IEEE Gold Book]")
      rule(:book_nickname) do
        space >> str("[") >> match("[^\\]]").repeat(1).as(:nickname) >> str("]")
      end

      # Relationship type keywords for Pattern 4 identifiers
      rule(:relationship_revision_of) do
        str("Revision of ") | str("Revison of ")
      end
      rule(:relationship_amendment_to) { str("Amendment to ") }
      rule(:relationship_corrigendum_to) do
        str("Corrigendum to ") | str("Corrigenda to ")
      end
      rule(:relationship_incorporates) do
        str("incorporates ") | str("Incorporating ") | str("Incorporates ")
      end
      rule(:relationship_adoption_of) { str("Adoption of ") }
      rule(:relationship_supplement_to) { str("Supplement to ") }
      rule(:relationship_draft_amendment) do
        str("Draft Amendment to ") | str("DRAFT Amendment to ")
      end
      rule(:relationship_draft_revision) { str("Draft Revision of ") }
      rule(:relationship_reaffirmation) { str("Reaffirmation of ") }
      rule(:relationship_redesignation) do
        str("Redesignation of ") | str("redesignated as ")
      end
      rule(:relationship_supersedes) { str("Supersedes ") | str("Supercedes ") }
      rule(:relationship_previously_designated) do
        str("Previously designated as ")
      end
      rule(:relationship_includes) { str("Includes ") } # NEW Session 171

      # Combined relationship type (longest match first)
      rule(:relationship_type) do
        relationship_draft_amendment.as(:draft_amendment_to) |
          relationship_draft_revision.as(:draft_revision_of) |
          relationship_previously_designated.as(:previously_designated_as) |
          relationship_reaffirmation.as(:reaffirmation_of) |
          relationship_redesignation.as(:redesignation_of) |
          relationship_supersedes.as(:supersedes) |
          relationship_includes.as(:includes) | # NEW Session 171
          relationship_revision_of.as(:revision_of) |
          relationship_amendment_to.as(:amendment_to) |
          relationship_corrigendum_to.as(:corrigendum_to) |
          relationship_incorporates.as(:incorporates) |
          relationship_adoption_of.as(:adoption_of) |
          relationship_supplement_to.as(:supplement_to)
      end

      # Identifier string (for parsing list of related identifiers)
      # Captures text until delimiter: comma, closing paren, "and", " / ", "; ", "as amended by"
      # Uses absent? to ensure we stop at these delimiters
      rule(:identifier_string) do
        (
          str(", and ").absent? >>
          str(" and ").absent? >>
          str(", ").absent? >>
          str(" as amended by ").absent? >>
          # Stop at any "/", ";", or "-" that introduces another relationship
          # (look-ahead: separator + relationship_type keyword). This lets the
          # slash inside "IEEE Std 525-2007/Cor 1-2015" stay part of the
          # identifier, while the slash before "Incorporates ..." splits.
          relationship_break.absent? >>
          str(")").absent? >>
          match(".")
        ).repeat(1)
      end

      # Identifier list (comma and "and" separated)
      rule(:identifier_list) do
        identifier_string.as(:id) >>
          (
            (str(", and ") | str(" and ") | str(", ")) >>
            identifier_string.as(:id)
          ).repeat
      end

      # "as amended by" clause with identifier list
      rule(:as_amended_by_clause) do
        # Variant 1: "as amended by IEEE's X, Y, Z"
        (str(" as amended by IEEE's ") >> identifier_list.as(:amendments)) |
          # Variant 2: "as amended by X, Y, Z" (standard)
          (str(" as amended by ") >> identifier_list.as(:amendments)) |
          # Variant 3: "and its approved amendments" (no specific list)
          str(" and its approved amendments").as(:approved_amendments)
      end

      # A character sequence that may separate two relationships inside the
      # parenthetical: a "/", ";", or "-" with optional surrounding spaces.
      # Standalone it is permissive — the actual decision to split is gated by
      # `relationship_break`, which requires another relationship_type to
      # follow. This way the slash in "IEEE Std 525-2007/Cor 1-2015" stays
      # part of the related identifier.
      rule(:relationship_separator) do
        (space.maybe >> str("/") >> space.maybe) |
          (space.maybe >> str(";") >> space.maybe) |
          (space.maybe >> str("-") >> space.maybe)
      end

      # Look-ahead: a separator followed by another relationship_type keyword.
      # Used as an absent? guard in identifier_string so the parser stops
      # consuming characters right before a new relationship begins.
      rule(:relationship_break) do
        relationship_separator >> space.maybe >> relationship_type
      end

      # Relationship clause (handles all relationship types)
      rule(:relationship_clause) do
        space.maybe >> str("(") >>
          relationship_type.as(:relationship_type) >>
          identifier_list.as(:related_ids) >>
          as_amended_by_clause.maybe >>
          # Additional relationships separated by "/", ";", or "-" (optionally
          # surrounded by spaces). The separator is only honored when followed
          # by another relationship_type — identifier-internal slashes like
          # "/Cor 1-2015" are not mistaken for relationship breaks because
          # identifier_string stops at relationship_break ahead.
          (
            relationship_separator >>
            relationship_type.as(:relationship_type) >>
            identifier_list.as(:related_ids) >>
            as_amended_by_clause.maybe
          ).repeat.as(:additional_rels) >>
          str(")")
      end

      # Title portion separated by colon (Category 8)
      rule(:title_portion) do
        str(":") >> space >> match('[^\n]').repeat(1).as(:title)
      end

      # Approved Draft suffix (Category 7)
      rule(:approved_draft_suffix) do
        (space >> str("- (Approved Draft)")) | (space >> str("(Approved Draft)"))
      end

      # Additional parameters (inside parentheses)
      rule(:additional_parameters) do
        (space.maybe >> str("(") >> space.maybe >> # Space before/after '(' optional
         # ("( Revision of …)" - a crawl space inside the paren must not push
         # the narrative to the catch-all and into the render).
         (reaffirmed |
          # Handle "Revision of IEEE Std ..." with optional space after Std
          (str("Revision of IEEE Std ") >> space.maybe >> match("[^)]").repeat(1).as(:revision_of)) |
          # Handle typo "Revison of IEEE Std ..." with optional space after Std
          (str("Revison of IEEE Std ") >> space.maybe >> match("[^)]").repeat(1).as(:revision_of)) |
          # Handle "Revision to IEEE Std ..." with optional space after Std
          (str("Revision to IEEE Std ") >> space.maybe >> match("[^)]").repeat(1).as(:revision_of)) |
          # Handle "Revison to IEEE Std ..." with optional space after Std
          (str("Revison to IEEE Std ") >> space.maybe >> match("[^)]").repeat(1).as(:revision_of)) |
          # Amendment patterns (case-insensitive DRAFT)
          ((str("DRAFT") | str("Draft") | str("draft")) >> str(" Amendment to ") >> match("[^)]").repeat(1).as(:draft_amendment_to)) |
          (str("Amendment to IEEE Std ") >> space.maybe >> match("[^)]").repeat(1).as(:amendment_to)) |
          # Adoption patterns
          (str("Adoption of ") >> match("[^)]").repeat(1).as(:adoption)) |
          # Other specific patterns
          (str("Notebooks") >> space? >> match("[^,\\)]").repeat(1).as(:notebooks)) |
          (str("Standard Newspaper(s)") >> space? >> match("[^,\\)]").repeat(1).as(:standard_newspapers)) |
          # Catch-all for any other parenthetical content (MUST BE LAST)
          match("[^)]").repeat(1).as(:parenthetical_content)
         ) >>
         str(")").maybe).as(:parameters)
      end

      # Parenthetical - try relationship_clause first, then fall back to additional_parameters
      rule(:parenthetical) do
        relationship_clause | additional_parameters
      end

      # IEC/IEEE copublished pattern - handle all variations comprehensively
      # BUT exclude P prefix patterns (those are joint development)
      rule(:iec_ieee_copublished) do
        str("IEC/IEEE") >>
          space >>
          str("P").absent? >> # NOT a P prefix (would be joint development)
          # The copublished number must contain at least one digit. This rejects
          # an all-letter placeholder like "IEC/IEEE TR" (no real document
          # number) — the same "require a digit" tightening the Standard number
          # rule got, applied to the copublished number grammar.
          (match("[^0-9\n]").repeat >> digit).present? >>
          match("[^\n]").repeat(1).as(:content)
      end

      # Joint development patterns (ISO/IEC/IEEE in either IEEE or ISO format)
      rule(:joint_development_ieee_format) do
        # ISO/IEC/IEEE P26511/D8-2018 or ISO/IEEE P1003.1-2008 or IEC/IEEE P62582-1-2011
        # ALSO handle: IEC/IEEE P60780-323, CDV1 2014 (comma before stage code)
        # ALSO handle: IEEE/CSA P844.1/293.1/D2 (CSA dual numbering)
        # ALSO handle: IEEE/ISO/IEC P42010/D=CD-2020 — the printed publisher
        # order is the organization's perspective (pubid#469) and parses as
        # printed; it is no longer rewritten to ISO-first.
        (str("ISO/IEC/IEEE") | str("IEEE/ISO/IEC") | str("ISO/IEEE") | str("IEC/IEEE") | str("IEEE/CSA")).as(:joint_publishers) >>
          space >>
          # P = project (the document is a draft): identity-bearing, so it
          # is captured and preserved, never silently consumed.
          str("P").as(:project_marker) >>
          digits.as(:number) >>
          ((dot | dash) >> digits.as(:part)).maybe >> # Optional part like .1 or -1
          # CSA dual numbering: /293.1 (second number)
          (slash >> digits >> (dot >> digits).maybe >> (dash >> digits.as(:draft_version)).maybe).maybe >>
          (
            # Variant 1b: the ordinal-less stage draft "D=CDV-2020" -
            # D (draft) = CDV (the IEC stage it drafts). The year rides in
            # the draft clause (a distinct key, so the builder keeps the
            # date inside the designator). The year follows IEEE format:
            # dash-joined ("D=CD-2020", the ruled canonical); the colon
            # spelling ("D=CDV:2020") stays accepted as the alias it was
            # frozen with. A dash-year is guarded to 19xx/20xx so a
            # YYMM monthcode tail can never be read as a year.
            (slash >> str("D") >> str("=") >>
              (str("CDV") | str("FDIS") | str("PWI") | str("WD") |
               str("NP") | str("DIS") | str("CD")).as(:draft_iso_stage) >>
              ((str(":") | str("-")) >>
               ((str("19") | str("20")) >> digit >> digit).as(:draft_stage_year)).maybe) |
            # Variant 1: /D8 notation (original), with the compound
            # both-systems suffix "=DDIS.3" (docs/IEEE-DRAFT-STAGES.md §1.3)
            (slash >> str("D") >> digits.as(:draft_version) >>
              (str("=") >> (str("D") >> (str("FDIS") | str("CDV") | str("PWI") |
                 str("DIS") | str("WD") | str("NP") | str("CD")) |
               (str("FDIS") | str("CDV") | str("PWI") | str("DIS") | str("WD") |
                str("NP") | str("CD"))).as(:draft_iso_stage) >>
               (dot | dash).maybe >> digits.as(:draft_iso_iteration).maybe).maybe) |
            # Variant 2: , CDV1 notation (comma before stage code) —
            # the stage draft of the named ISO/IEC stage, its iteration
            (comma >> (str("CDV") | str("FDIS") | str("CD") | str("DIS")).as(:iec_stage) >> digits.maybe.as(:stage_iteration))
          ).maybe >>
          # Optional edition, from relaton's "/E-<n>" suffix normalized to
          # "Edition <n>.0[ YYYY]" (nil-residue hand-off item 1). The edition
          # rule carries its own year, so the year clause below simply doesn't
          # fire when an edition is present.
          edition.maybe >>
          ((dash >> year_digits.as(:year)) | # Either -YEAR
           (comma.maybe >> space >> month_name.as(:month) >> space.maybe >> year_digits.as(:year))).maybe >> # Or Month YEAR (with optional comma)
          revision_suffix.maybe
      end

      rule(:joint_development_iso_format) do
        # ISO-led stage designations. Two spellings:
        #   colon form  : "ISO/IEC/IEEE FDIS 26511:2018"           (already used)
        #   corpus form : "ISO/IEC/IEEE FDIS P26515-2018-05"       (historical)
        # The corpus form adds a leading "P" on the number, a trailing
        # "-YYYY[-MM]" date (instead of ":YYYY"), multi-digit committee-draft
        # stage codes (CD1..CD4) plus CDV, and a wider set of joint publishers.
        # (roadmap items 2/3, phase 1). longest publisher token first.
        # The stage is OPTIONAL ONLY for ISO-led joint prefixes - the
        # stage-less PUBLISHED form (pubid#317): "ISO/IEC/IEEE 26511:2018",
        # "ISO/IEEE 11073-20101:2004(E)". Every other prefix keeps the
        # stage REQUIREMENT so this rule cannot steal what belongs to
        # iec_ieee_copublished ("IEC/IEEE 60076-2016"), the bare-IEEE
        # project rules ("IEEE P802.16/D-3") or the ISO flavor
        # ("ISO/IEC <n>:<year>").
        iso_led = (str("ISO/IEC/IEEE") | str("IEEE/ISO/IEC") |
                   str("IEEE/IEC/ISO") | str("ISO/IEEE"))
        staged_only = (str("IEC/IEEE") | str("IEEE/IEC") |
                       str("ISO/IEC") | str("IEEE"))
        # ISO stage codes: FDIS, FCD, CDV; DIS/CD with an optional round
        # digit (DIS2, CD1..CD4); WD/PWI/NP.
        iso_stage = (str("FDIS") | str("FCD") | str("CDV") |
                     (str("DIS") >> digit.maybe) |
                     (str("CD") >> digit.maybe) |
                     str("WD") | str("PWI") | str("NP")).as(:iso_stage)
        std_noise = (space >> str("Std")).maybe
        # The empty-string marker distinguishes the stage-less PUBLISHED
        # tree in the builder (absence of :iso_stage alone means IEEE format).
        ((iso_led.as(:joint_publishers) >> space >>
           (iso_stage >> std_noise >> space |
            str("").as(:iso_published) >> space.maybe)) |
          (staged_only.as(:joint_publishers) >> space >>
            iso_stage >> std_noise >> space)) >>
          str("P").as(:project_marker).maybe >> # project marker (P =
                                                # project/draft; its
                                                # presence is identity)
          digits.as(:number) >>
          # part must not swallow the trailing year (year_digits.absent?). A
          # DASH-joined part is tagged (:part_dash) - the catalogue-printed
          # joint form spells the part with a dash ("21451-7") where the ISO
          # form uses the dot.
          ((dot >> year_digits.absent? >> digits.as(:part)) |
           (dash >> str("").as(:part_dash) >> year_digits.absent? >>
             digits.as(:part))).maybe >>
          (
            (str(":") >> year_digits.as(:year)) |
            # The dash-year (and ", Month YYYY" text date below) spellings are
            # the catalogue-PRINTED joint form; tag them (:printed_form) so the
            # builder routes to a Standard instead of the ISO joint reference.
            (dash >> year_digits.as(:year) >>
             (dash >> month_numeric.as(:month)).maybe >>
             str("").as(:printed_dash_year)) |
            # Trailing text date ", April 2015" / " April 2015" (build_joint_development
            # already reads :month/:year). No :year collision — the iso rule has no
            # other :year capture (edition uses :edition_year).
            ((comma | space) >> month_name.as(:month) >> space >>
             year_digits.as(:year) >> str("").as(:printed_month_year))
          ).maybe >>
          # Optional /D<draft> tail; the historical hyphenated form
          # "…/D-3-2017" carries its date inside the draft clause (bucket 5);
          # a date-less "/D-4" keeps its hyphen (bucket 7), hence dash.maybe.
          # A text date may trail the DRAFT itself (pubid#216:
          # "CD P26515/D1, March 2017", "FDIS P15289/D3, 2017") — distinct
          # keys (:draft_month/:draft_year), because a plain :month/:year
          # here collides with the date clause above and parslet drops the
          # subtree with a "Duplicate subtrees" warning.
          # The ISO/IEC edition marker may sit between the year and an
          # amendment/draft tail: "8802.11:2012 (E)/Amd 1-2014". A distinct
          # key - a second :parameters capture here collides with the
          # trailing parenthetical slot (parslet drops duplicate subtrees).
          (space.maybe >> str("(") >>
           match("[^)]").repeat(1).as(:edition_marker) >> str(")")).maybe >>
          # The stage-draft clause of the ISO-led print: "/D=WD.5" -
          # D (draft) = the ISO/IEC stage it drafts, with its iteration
          # (docs/IEEE-DRAFT-STAGES.md §1.2).
          ((slash >> str("D") >> str("=") >>
           (str("FDIS") | str("FCD") | str("CDV") |
            (str("DIS") >> digit.maybe) |
            (str("CD") >> digit.maybe) |
            str("WD") | str("PWI") | str("NP")).as(:draft_iso_stage) >>
           (dot >> (digits >> match("[A-Za-z]").repeat(0, 1)).as(:draft_iso_iteration)).maybe) |
          (slash >> str("D") >> dash.maybe >>
           match('[0-9.]').repeat(1).as(:draft_version) >>
           (((comma | space) >> month_name.as(:draft_month) >> space >>
               year_digits.as(:draft_year)) |
             (comma >> year_digits.as(:draft_year))).maybe).maybe).maybe >>
          # Optional amendment tail (pubid#317:
          # "8802-11:2012/Amd.1:2014(E)") - the flat tree keys reuse
          # build_flat_amendment.
          (slash >> str("Amd") >> (dot | space).maybe >>
           digits.as(:amd_number) >>
           ((str(":") | dash) >> year_digits.as(:amd_year)).maybe).maybe >>
          # Optional corrigendum tail, the ISO print's dotted spelling
          # (pubid#215): "8802-1AC:2018/Cor.1:2020(E)". The shared
          # corrigendum rule accepts the slash/dot/colon separators; the
          # flat tree routes through build_flat_corrigendum.
          corrigendum.maybe >>
          # Optional edition, from relaton's "/E-<n>" suffix normalized to
          # "Edition <n>.0[ YYYY]" (nil-residue hand-off item 1).
          edition.maybe >>
          revision_suffix.maybe >>
          # A redline is a distinct document of the joint ISO print
          # (pubid#215): "15289:2015(E) - Redline". Same flag semantics as
          # the generic rules - the builder sets redline: true.
          redline.maybe >>
          # Published joint docs print a language marker, after either the
          # year or the amendment tail: "9945:2009(E)", "...Amd.1:2014(E)".
          # The crawl sometimes spaces it ("…(E), January 2017" family,
          # pubid#216), and a relationship parenthetical may follow
          # ("…CD2 P15288-2013-09 (Revision of …)").
          parenthetical.maybe
      end

      # Embedded (stage-LAST) ISO-led designations: the corpus writes the ISO
      # stage AFTER the (dotted or dashed) part —
      #   "ISO/IEC/IEEE 29119.4.FDIS, April 2015"   (dot part .4, stage .FDIS)
      #   "ISO/IEC/IEEE 24748-5.CD3, February 2015" (dash part -5, stage .CD3)
      #   "IEEE P24748.5.CD3, July 2015"            (bare IEEE + P)
      # — rather than before the number (joint_development_iso_format). Same
      # meaning as the stage-first form: `29119.4`/`29119-4` = "29119 part 4" and
      # the trailing `.FDIS` is the ISO stage, NOT a second part. Routes through
      # the same build_joint_development (via :joint_publishers/:iso_stage), so the
      # stage is modeled correctly and the numeric part stays separate.
      # The stage-less ISO/IEC label with a colon year and the ISO/IEC
      # edition marker: "ISO/IEC 13210:1994 (E)" - the ISO/IEC portion of a
      # double-labeled standard. The (E) parenthetical is REQUIRED: without
      # it this spelling is the ISO flavor's own form and must not be
      # stolen. Routes through build_joint_development like every ISO-led
      # joint reference.
      rule(:joint_development_iso_iec_edition) do
        str("ISO/IEC").as(:joint_publishers) >> space >>
          str("").as(:iso_published) >>
          str("P").as(:project_marker).maybe >>
          digits.as(:number) >>
          # The part may be dot- or dash-joined ("8802-9"); a dash-year
          # ("1234-2012") is not a part.
          # A distinct key: the iso-format route's :part_dash prints as a
          # dot in the joint code (the "P24748.2:2018" convention); only
          # the ISO/IEC LABEL keeps its printed dash.
          ((dot | (dash >> str("").as(:iec_label_dash) >> year_digits.absent?)) >>
            digits.as(:part)).maybe >>
          (str(":") >> space.maybe >> year_digits.as(:year)) >>
          space.maybe >> parenthetical
      end

      rule(:joint_development_embedded_stage) do
        # publisher set mirrors joint_development_iso_format (incl. bare IEEE);
        # longest token first.
        (str("ISO/IEC/IEEE") | str("IEEE/ISO/IEC") | str("IEEE/IEC/ISO") |
         str("ISO/IEEE") | str("IEC/IEEE") | str("IEEE/IEC") | str("ISO/IEC") |
         str("IEEE")).as(:joint_publishers) >>
          space >>
          str("P").as(:project_marker).maybe >> # project marker (P =
                                                # project/draft; its
                                                # presence is identity)
          digits.as(:number) >>
          # optional numeric part (dot or dash); must not swallow a year
          ((dot | dash) >> year_digits.absent? >> digits.as(:part)).maybe >>
          # the embedded stage, dot-separated, closed vocab (same as iso_stage).
          # The (digit|letter) look-ahead keeps it at a token boundary so "CD"
          # can't match inside a longer token and a glued no-space date
          # (".DISMay2013") is left to fall through.
          dot >>
          (str("FDIS") | str("FCD") | str("CDV") |
           (str("DIS") >> digit.maybe) |
           (str("CD") >> digit.maybe) |
           str("WD") | str("PWI") | str("NP")).as(:iso_stage) >>
          (digit | match("[A-Za-z]")).absent? >>
          # optional trailing date: :YYYY, -YYYY[-MM], or text "Month YYYY"
          (
            (str(":") >> year_digits.as(:year)) |
            (dash >> year_digits.as(:year) >>
             (dash >> month_numeric.as(:month)).maybe) |
            ((comma | space) >> month_name.as(:month) >> space >> year_digits.as(:year))
          ).maybe
      end

      # Number-first pattern: "1873-2015 IEEE Standard..."
      rule(:number_first_identifier) do
        number >>
          (dash >> year_digits.as(:year)).maybe >>
          space >>
          (publisher >> copublisher.repeat.as(:copublishers)).as(:publishers) >>
          space >>
          (type_word.as(:type) >> space?).maybe >>
          match("[^\n]").repeat(0).as(:title)
      end

      # IEEE P pattern (without Std): "IEEE P1003.1..." OR just "P1003.1..." (prefix optional)
      # `P` is not consumed here: the `number` rule carries its own optional
      # leading P and captures it into :number ("P1003.1"), so Code.parse
      # peels it as code.prefix and the project marker survives the parse —
      # a bare `str("P")` swallowed it and "P1201/D0.3" came back without
      # its P at all (pubid#18's data-loss complaint).
      rule(:ieee_p_identifier) do
        (str("IEEE").as(:publisher) >> space).maybe >> # Make IEEE prefix optional
          number >>
          (part_subpart_year | edition).maybe >>
          # Pattern for /08 style drafts (digits without D prefix) - MUST come before corrigendum
          (slash >> digits.as(:draft_version)).as(:digit_draft).maybe >>
          # FDIS and other ISO stage codes without D prefix (Pattern 3)
          fdraft.maybe >>
          # Trailing "Month YYYY" print/reaffirm date. Captured under distinct
          # keys so it never collides with the base -YYYY identity year (a
          # collision made Parslet drop the base year and warn "Duplicate
          # subtrees … keys: [:year]"). The builder promotes it to the identity
          # only when there is no base year.
          trailing_month_year.maybe >>
          corrigendum.maybe >>
          draft.maybe >>
          # Revision trails the draft (before any date), matching normalization's
          # ".../D<n>/R-<x>" repositioning of "P802.16Rev2/D3 Feb 2008".
          revision_suffix.maybe >>
          # ALSO accept month/year after draft (some patterns like /DX, Month YEAR)
          trailing_month_year.maybe >>
          # Trailing corrigendum AFTER the draft+date ("…/D1, Jan 2007/Cor. 1").
          # The draft's own draft_date has already consumed the date, leaving
          # "/Cor. 1" here; the resulting flat corrigendum+draft tree routes to
          # build_flat_corrigendum (disjoint from the pre-draft corrigendum slot,
          # which only fires when no draft precedes it).
          corrigendum.maybe >>
          parenthetical.maybe
      end

      # ANSI P pattern: "ANSI PN42.34-D9a, 2015" OR "ANSI P1234/D5"
      rule(:ansi_p_identifier) do
        str("ANSI").as(:publisher) >> space >>
          str("P") >> space.maybe >> # Make space after P optional
          number >>
          (part_subpart_year | edition).maybe >>
          # Trailing "Month YYYY"/bare-year date under distinct keys so they
          # never collide with the base -YYYY identity year (see ieee_p_identifier).
          trailing_month_year.maybe >>
          corrigendum.maybe >>
          draft.maybe >>
          revision_suffix.maybe >>
          # ALSO accept month/year after draft
          trailing_month_year.maybe >>
          # Accept bare year after draft: ", 2015"
          ((comma | space) >> year_digits.as(:trailing_year)).maybe >>
          # Trailing corrigendum after the draft+date (parity with ieee_p_identifier).
          corrigendum.maybe >>
          parenthetical.maybe
      end

      # IEEE Draft P pattern: "IEEE Draft P802.11..." OR "Draft P802.11..." (IEEE prefix optional)
      # An optional status phrase may precede "Draft" — "IEEE Unapproved Draft P…",
      # "IEEE Active Approved Draft P…" — the largest index-v2 draft bucket. The
      # status is captured (draft_status ends in a space, so "Approved Draft"
      # splits cleanly) and round-trips as the draft_status attribute; the literal
      # "Draft" stays a bare marker (dropped on render, like the plain form).
      # `P` is not consumed here: the `number` rule carries its own optional
      # leading P and captures it into :number ("P802.11"), so Code.parse peels
      # it as code.prefix and the project marker round-trips (pubid#318) — a
      # bare `str("P").maybe` here swallowed it and the render lost the P.
      rule(:ieee_draft_p_identifier) do
        (str("IEEE").as(:publisher) >> space).maybe >> # Make IEEE prefix optional
          draft_status.as(:draft_status).maybe >>
          str("Draft") >> space >>
          # A status-word draft may carry a bare number
          # ("IEEE Unapproved Draft 802.1ah/D4.2"). The `number` rule
          # already accepts the bare forms (802.1ah, C57.15, 11073-10471).
          number >>
          (part_subpart_year | edition).maybe >>
          # Trailing "Month YYYY" date under distinct keys so it never collides
          # with the base -YYYY identity year (see ieee_p_identifier).
          ((space >> month_name.as(:trailing_month) >> space >> year_digits.as(:trailing_year)) |
           (space >> month_numeric.as(:trailing_month) >> (space | dash) >> year_digits.as(:trailing_year))).maybe >>
          draft.maybe >>
          # A print date may trail a draft that carries its own date
          # ("IEEE Unapproved Draft 24765/D1 2009, Oct 2009" - the draft's
          # year is "2009", the print date is ", Oct 2009").
          (comma >> space? >> month_name.as(:trailing_month) >> space >>
            year_digits.as(:trailing_year)).maybe >>
          revision_suffix.maybe >>
          # …and the print date may also trail the repositioned revision
          # ("IEEE Unapproved Draft P802.16Rev2/D9a, March 2009" reaches the
          # grammar with its inline revision parsed natively).
          (comma >> space? >> month_name.as(:trailing_month) >> space >>
            year_digits.as(:trailing_year)).maybe >>
          # Trailing corrigendum after the draft ("…/D2.0/Cor. 1", or
          # "…/D1.0, Dec 2007/Cor. 1" where the draft's own draft_date consumes
          # the date, leaving "/Cor. N"). The flat corrigendum+draft tree (no
          # :base) routes to build_flat_corrigendum, which rebuilds the base
          # standard (carrying the draft + draft_status) and wraps it.
          corrigendum.maybe >>
          parenthetical.maybe
      end

      # IEEE Approved Draft pattern: "IEEE Approved Draft Std P..."
      rule(:ieee_approved_draft_identifier) do
        str("IEEE").as(:publisher) >>
          space >>
          str("Approved") >> space >>
          (str("Draft Std") | str("Std")).as(:type) >> space >>
          str("P").maybe >>
          number >>
          (part_subpart_year | edition).maybe >>
          draft.maybe >>
          revision_suffix.maybe >>
          parenthetical.maybe
      end

      # Combined AIEE identifier pattern: "AIEE No 72-1932 and AIEE No 73-1932"
      # Handles "and"-separated AIEE identifiers (from "Nos X and Y" preprocessing)
      rule(:combined_aiee_identifier) do
        # First AIEE identifier
        Aiee::Parser.new.aiee_identifier.as(:first_aiee) >>
          # "and" separator
          space >> str("and") >> space >>
          # Second AIEE identifier
          Aiee::Parser.new.aiee_identifier.as(:second_aiee)
      end

      # AIEE (American Institute of Electrical Engineers) patterns
      # Detect AIEE patterns and delegate to AIEE parser
      rule(:aiee_identifier) do
        # Lookahead for AIEE patterns - do not consume input
        (
          # IEEE-AIEE transitional pattern
          (str("IEEE-AIEE") >> space >> (str("No.") | str("Nos") | str("No") | str("Standard") | str("Trans."))) |
          # A.I.E.E. pattern (with dots, no spaces)
          (str("A.I.E.E.") >> space >> (str("No.") | str("Nos") | str("No"))) |
          # A. I. E. E. pattern (with dots and spaces)
          (str("A. I. E. E.") >> space >> (str("No.") | str("Nos") | str("No") | str("Standard"))) |
          # AIEE pattern - extended to include more type words
          (str("AIEE") >> space >> (str("No.") | str("Nos") | str("No") | str("Standard") | str("Trans.") | str("Std")))
        ).present? >>
          # Delegate to AIEE parser if pattern detected
          Aiee::Parser.new.aiee_identifier.as(:aiee)
      end

      # IRE (Institute of Radio Engineers) patterns
      # Detect IRE patterns and delegate to IRE parser
      rule(:ire_identifier) do
        # Lookahead for IRE patterns - do not consume input
        (
          # Year-first pattern: "52 IRE 7.S2" or "60 IRE 28 PS7"
          ((match("[1-6]") >> digit >> space >> str("IRE")) | # 2-digit year format
           (str("19") >> digit.repeat(2, 2) >> space >> str("IRE"))) |
          # Prefix-first pattern: "IRE 7.S2-1952" (pubid#316 family 2) —
          # IRE then a designation (digits or a type word). Loose on
          # purpose: the sub-parser is strict, and a failed delegation just
          # falls through to the remaining alternatives.
          (str("IRE") >> space >> (digits | str("Standard") | str("Std") | str("Trans"))) |
          # IEEE-IRE transitional pattern
          (str("IEEE-IRE") >> space)
        ).present? >>
          # Delegate to IRE parser if pattern detected
          Ire::Parser.new.ire_identifier.as(:ire)
      end

      # NESC (National Electrical Safety Code) patterns
      # Detect NESC patterns and delegate to NESC parser
      rule(:nesc_identifier) do
        # Lookahead for NESC patterns - do not consume input
        (
          # C2-YYYY pattern
          (str("C2-") >> year_digits) |
          # YYYY NESC pattern
          (year_digits >> space >> (str("NESC") | str("National Electrical Safety Code"))) |
          # Draft NESC pattern
          (str("Draft") >> space >> (str("NESC") | str("National Electrical Safety Code"))) |
          # Name-first pattern (NEW)
          (str("National Electrical Safety Code") >> str(",") >> space >> str("C2-")) |
          # Catalogue form: "IEEE Std YYYY NESC ..." / "IEEE Std YYYY National
          # Electrical Safety Code" - the prefix is consumed here (the NESC
          # renderer prepends "IEEE Std" itself) but must not fall through to
          # the generic standard grammar, which would read YYYY as a number.
          (str("IEEE") >> space >> str("Std") >> space >> year_digits >> space >>
            (str("NESC") | str("National Electrical Safety Code")))
        ).present? >>
          # Delegate to NESC parser if pattern detected
          ((str("IEEE") >> space >> str("Std") >> space).maybe >>
            Nesc::Parser.new.nesc_identifier).as(:nesc)
      end

      # Draft notation for PSI (e.g., /D2, /D3, rawbib's /D-2)
      rule(:psi_draft) do
        slash >> str("D") >> dash.maybe >> digits.as(:draft_version)
      end

      # Date on an SI/PSI identifier: ", Month Year" or "-YEAR[-MM]". The
      # comma branch also accepts a NUMERIC month and a DASH before the
      # year — the renderer emits ", 05 2010" for a numeric-month draft,
      # and the preprocessing gsub rewrites a trailing " <digits> <year>"
      # to "<digits>-<year>" (the same load-bearing coupling draft_date
      # documents), so the re-parse must read its own rendering back.
      rule(:psi_date) do
        (comma >> (month_name | month_numeric).as(:month) >> (space | dash) >>
           year_digits.as(:year)) |
          (dash >> year_digits.as(:year) >>
            (dash >> digit.repeat(2, 2).as(:month)).maybe)
      end

      # IEEE/ASTM SI/PSI (Système International) patterns
      # SI = Published metric system standard
      # PSI = Proposed SI (draft)
      # Rawbib spellings (pubid#316 family 3): a bare "IEEE" publisher, a dot
      # separator after the type ("PSI.10", "SI 10.1997"), relaton's
      # hyphenated "/D-<n>" draft, and a dash year-month ("-2010-05").
      rule(:ieee_astm_si_psi) do
        (str("IEEE/ASTM") | str("IEEE")).as(:publishers) >>
          space >>
          (str("PSI") | str("SI")).as(:si_type) >>
          (space | str(".")) >>
          digits.as(:number) >>
          # Glued ".YEAR" edition date ("IEEE/ASTM SI 10.1997")
          (str(".") >> year_digits.as(:year)).maybe >>
          # The date and the draft appear in EITHER order: the legacy
          # spelling puts the draft first ("PSI 10/D2, October 2015"),
          # the rawbib hyphenated form ("PSI 10/D-3-2010") parses in place
          # with its date on the draft clause. Draft-first is tried first so the legacy
          # comma-date keeps its original match; each side is optional so
          # a date-only or draft-less form still parses.
          (
            (psi_draft >> psi_date.maybe) | (psi_date >> psi_draft.maybe)
          ).maybe >>
          # Optional parenthetical (revision relationships)
          parenthetical.maybe
      end

      # No-prefix IEEE identifier (characteristic patterns without "IEEE Std")
      # These are patterns that are distinctly IEEE even without explicit publisher
      rule(:no_prefix_ieee) do
        characteristic_ieee_number.as(:number) >>
          # Optional suffix (like -a, -b)
          (dash >> match("[A-Za-z]")).maybe.as(:suffix) >>
          # Optional year
          (dash >> year_digits).maybe.as(:year) >>
          # Optional draft notation
          draft.maybe >>
          # Optional language portion
          (str("(E)") | str("(F)")).maybe >>
          # Optional parenthetical content
          parenthetical.maybe
      end

      # Corrigendum identifier with recursive base parsing
      # Captures base identifier for recursive parsing, then corrigendum supplement
      # Example: IEEE Std 535-2013/Cor. 1-2017
      rule(:corrigendum_identifier) do
        # Match a complete base identifier (reuse existing patterns)
        # Try standard patterns that would match "IEEE Std 535-2013"
        (
          ((publisher >> copublisher.repeat.as(:copublishers)).as(:publishers) >> space).maybe >>
          (type_word.as(:type) >> space?).maybe >>
          number >>
          part_subpart_year.maybe # This captures the full identifier before /Cor
        ).as(:base) >>
          # Now match the corrigendum portion
          (slash | dash | space) >>
          str("Cor") >>
          (dash | dot | space).maybe >> # More flexible separator after "Cor"
          space? >>
          digits.as(:cor_number) >>
          ((dash | str(":") | space) >> year_digits.as(:cor_year)).maybe >> # Optional cor year suffix
          parenthetical.maybe
      end

      # Interpretation identifier with recursive base parsing
      # Captures base identifier for recursive parsing, then interpretation supplement
      # Example: IEEE Std 1076/INT-1991, IEEE Std 1003.1-1988/INT
      rule(:interpretation_identifier) do
        # Match a complete base identifier
        (
          ((publisher >> copublisher.repeat.as(:copublishers)).as(:publishers) >> space).maybe >>
          (type_word.as(:type) >> space?).maybe >>
          number >>
          part_subpart_year.maybe
        ).as(:base) >>
          # Now match the interpretation portion
          (slash | dash | space) >>
          str("INT") >>
          ((dash | str(":") | space) >> year_digits.as(:int_year)).maybe >> # Optional year suffix
          parenthetical.maybe
      end

      # Conformance identifier with recursive base parsing
      # Captures base identifier for recursive parsing, then conformance supplement
      # Example: IEEE Std 802.16/Conformance01-2003
      rule(:conformance_identifier) do
        # Match a complete base identifier
        (
          ((publisher >> copublisher.repeat.as(:copublishers)).as(:publishers) >> space).maybe >>
          (type_word.as(:type) >> space?).maybe >>
          number >>
          part_subpart_year.maybe
        ).as(:base) >>
          # Now match the conformance portion
          (slash | dash | space) >>
          str("Conformance") >>
          match("[0-9]").repeat(1).as(:conf_number) >>
          dash >>
          year_digits.as(:conf_year) >>
          parenthetical.maybe
      end

      # Multi-numbered identifier: same document with multiple numbers
      # Examples: IEEE Std 1299/C62.22.1-1996, IEEE Std 960-1989, Std 1177-1989
      rule(:multi_numbered_identifier) do
        # Primary identifier (full IEEE identifier)
        ((
          (publisher >> space).maybe >>
          (type_word.as(:type) >> space?).maybe >>
          number >>
          (part_subpart_year | edition).maybe
        ).as(:primary_identifier) >>
          # Separator: slash for cross-ref format, comma for joint standard
          (slash >> str("C") >> digits >> dot >> digits >> dot >> digits >> dash >> year_digits).as(:secondary_crossref)) |
          (comma >> space >> (type_word.as(:type) >> space?).maybe >> number >> dash >> year_digits).as(:secondary_joint)
      end

      # CSA dual published pattern: IEEE Std 844.1-2017/CSA C22.2 No. 293.1-17
      rule(:csa_dual_published) do
        # IEEE portion (full identifier)
        (
          publisher >> space >>
          (type_word.as(:type) >> space?).maybe >>
          number >>
          (part_subpart_year | edition).maybe
        ).as(:ieee_portion) >>
          # CSA portion with slash separator
          slash >>
          str("CSA") >> space >>
          # CSA number formats (various patterns observed)
          (
            # Format 1: C22.2 No. 293.1-17 (with NO., either case)
            (str("C") >> digit.repeat(2) >> dot >> digit >> space >> (str("No") | str("NO")) >> dot >> space >>
             match("[0-9.]").repeat(1) >> (dash | str(":")) >> digit.repeat(2)) |
            # Format 2: C293.2-17 (without NO., dash year)
            (str("C") >> match("[0-9.]").repeat(1) >> dash >> digit.repeat(2)) |
            # Format 3: C22.2 No. 293.3:19 (with NO., either case, colon year)
            (str("C") >> digit.repeat(2) >> dot >> digit >> space >> (str("No") | str("NO")) >> dot >> space >>
             match("[0-9.]").repeat(1) >> str(":") >> digit.repeat(2)) |
            # Format 4: C293.4:19 (without NO., colon year)
            (str("C") >> match("[0-9.]").repeat(1) >> str(":") >> digit.repeat(2))
          ).as(:csa_portion)
      end

      # Basic IEEE identifier (no dual PubIDs or complex revisions yet)
      rule(:identifier) do
        combined_aiee_identifier |
          aiee_identifier |
          combined_aiee_identifier |
          ire_identifier |
          nesc_identifier |
          ieee_astm_si_psi | # NEW Session 171: Add IEEE/ASTM SI/PSI support
          multi_numbered_identifier | # NEW: Try multi-numbered identifiers before generic patterns
          csa_dual_published | # NEW: Try CSA dual published before generic patterns
          s_designation | # Historical IEEE/IPCEA cable designation (S-135)
          corrigendum_identifier | # NEW: Try corrigendum before generic patterns
          interpretation_identifier | # NEW: Try interpretation identifier before generic patterns
          conformance_identifier | # NEW: Try conformance identifier before generic patterns
          joint_development_ieee_format |
          joint_development_iso_format |
          joint_development_iso_iec_edition | # stage-less ISO/IEC label with (E) - double-label portion

          joint_development_embedded_stage | # stage-LAST embedded form (before generic)
          iec_ieee_copublished |
          number_first_identifier |
          ieee_approved_draft_identifier |
          ieee_draft_p_identifier |
          ieee_p_identifier |
          ansi_p_identifier | # NEW: ANSI P prefix support
          (((publisher >> copublisher.repeat.as(:copublishers)).as(:publishers) >> space).maybe >> # Make publisher optional
          draft_status.as(:draft_status).maybe >>
          (str("Draft Std").as(:type) >> space?).maybe >>
          (type_word.as(:type) >> (space >> str("No") >> space).maybe >> space?).maybe >>
          number >>
          (part_subpart_year | edition).maybe >>
          corrigendum.maybe >>
          amendment.maybe >>
          interpretation.maybe >> # NEW: Add /INT support
          conformance.maybe >> # NEW: Add /Conformance support
          ashrae_copub.maybe >> # NEW: Add /ASHRAE Guideline support
          ieee_crossref.maybe >> # NEW: Add /C62.22.1-1996 cross-reference support
          draft.maybe >>
          revision_suffix.maybe >>
          # Trailing "Month YYYY" print/reaffirm date under distinct keys so it
          # never collides with the base -YYYY identity year (see
          # ieee_p_identifier). The builder promotes it only when no base year.
          trailing_month_year.maybe >>
          # The ASHRAE joint suffix may also trail a draft+date
          # ("IEEE P1635/D13, December, 2017/ASHRAE Guideline 21"), so a
          # second slot catches it after the date.
          ashrae_copub.maybe >>
          # A bracketed narrative may sit between the base and a trailing
          # corrigendum: "IEEE Std 671-1985 [Corrigendum to IEEE Std 671-1985
          # (Reaff 2008)]/Cor. 1-2010" captures the bracket as the base's
          # nickname before the wrapper is parsed.
          book_nickname.maybe >>
          # Trailing corrigendum after the draft+date ("IEEE Approved P1015/D1,
          # Jan 2007/Cor. 1"): the generic bucket is the only path a status-word
          # form reaches. Routes via build_flat_corrigendum (disjoint from the
          # pre-draft corrigendum slot at line 954).
          corrigendum.maybe >>
          edition.maybe >>
          parenthetical.maybe >>  # REVERT: Back to single parenthetical
          book_nickname.maybe >>  # NEW: Add book nickname support
          redline.maybe >>
          title_portion.maybe >>
          approved_draft_suffix.maybe) |
          no_prefix_ieee # NEW: Try no-prefix patterns last (lowest priority)
      end

      root(:identifier)
      def self.normalize_input(string)
        # Strip .pdf extension if present (Pattern 3: File Extensions)
        cleaned = string.sub(/\.pdf$/i, "")

        # Note: IEC and ANSI identifiers are NOT filtered here because they can have
        # IEEE co-publication or adoption. The Base.parse method handles determining
        # which standards are actually IEEE-related.
        # ISO-only standards are still filtered as they have separate handling.

        # NEW: Normalize multiple spaces to single space
        # No valid IEEE identifier pattern needs more than 1 space
        cleaned = cleaned.gsub(/\s+/, " ")


        # NEW Session 171: Remove wrong ! prefix
        cleaned = cleaned.gsub(/^!IEEE /, "IEEE ")

        # NEW Phase 1: Handle HTML entities comprehensively
        cleaned = cleaned.gsub("&#x2122;", "™") # Trademark symbol
        cleaned = cleaned.gsub("&#x2019;", "'") # Smart apostrophe
        cleaned = cleaned.gsub("&amp;amp;", "&")   # Double-encoded ampersand
        cleaned = cleaned.gsub("&amp;", "&")       # Single-encoded ampersand

        # The joint IEEE/CSA catalogue spells the type word before the
        # project number ("IEEE/CSA Draft P844.1/D2, Sept, 2016"): the P
        # already carries the project semantics (docs/IEEE-DRAFT-STAGES.md
        # §1.1), so the redundant word drops and the joint route parses.
        cleaned = cleaned.gsub(%r{IEEE/CSA Draft (P[A-Z0-9])}, 'IEEE/CSA \1')

        # The corrigendum's own draft follows the ordinal after a comma
        # ("P11073-10418-2011/Cor 1, D4, July 2015"): re-spell the comma as
        # the draft separator so the cor route's draft slot reaches it.
        cleaned = cleaned.gsub(%r{/Cor(?:rigendum)? (\d+), (D[A-Z0-9])}, '/Cor \1/\2')

        # The corrigendum's own draft rides before the ordinal in the
        # house order ("PC37.101-2006/D2, 2007/Cor. 1"): the catalogue
        # spellings "…/Cor 1, D4, July 2015" and "…/Cor 1-201x/D5,
        # April 2012" re-order into it, with the draft's date glued
        # -YYYY-MM (pubid ruling 2026-10-14: no comma dates).
        cleaned = cleaned.gsub(
          %r{/Cor(?:rigendum)? (\d+(?:-[0-9xX]{4})?)/(D[A-Z0-9][^,]*), ([A-Za-z]+) (\d{4})}
        ) do
          month = ::Pubid::Ieee::Builder::REV_MONTH_NUMBERS[Regexp.last_match(3).capitalize]
          if month
            "/#{Regexp.last_match(2)}-#{Regexp.last_match(4)}-#{month}/Cor. #{Regexp.last_match(1)}"
          else
            Regexp.last_match(0)
          end
        end
        cleaned = cleaned.gsub(
          %r{/Cor(?:rigendum)? (\d+), (D[A-Z0-9][^,]*), ([A-Za-z]+) (\d{4})}
        ) do
          month = ::Pubid::Ieee::Builder::REV_MONTH_NUMBERS[Regexp.last_match(3).capitalize]
          if month
            "/#{Regexp.last_match(2)}-#{Regexp.last_match(4)}-#{month}/Cor. #{Regexp.last_match(1)}"
          else
            Regexp.last_match(0)
          end
        end

        # NEW Phase 1: Fix number spacing issues (e.g., "C57.1 2.25" → "C57.12.25")
        # This handles cases where a space appears in the middle of a number
        cleaned = cleaned.gsub(/(\d+\.\d+)\s+(\d+\.)/, '\1\2')

        # NEW Phase 1: Fix year spacing issues (e.g., "1 996" → "1996")
        # Remove spaces within 4-digit years
        cleaned = cleaned.gsub(/\b(1|2)\s+(\d{3})\b/, '\1\2')

        # NEW: Convert IEC/IEEE space-separated to semicolon format
        # Pattern: "IEC 61523-3 First edition 2004-09; IEEE 1497" → already semicolon
        # Pattern: "IEC 62539 First Edition 2007-07 IEEE 930" → needs semicolon
        # Pattern: "IEC 60076-21:2011 Edition 1.0 2011-12 IEEE Std C57.15" → needs semicolon (issue #202)
        # Match: IEC identifier (with optional colon-year, optional "First"/numeric
        # Edition + YYYY-MM) + space + IEEE identifier.
        cleaned = cleaned.gsub(
          /(IEC\s+\d+(?:-\d+)?(?::\d{4})?(?:\s+(?:First\s+)?[Ee]dition\s+\d+(?:\.\d+)?\s+\d{4}-\d{2})?)\s+(IEEE\s+Std\s+\S+|IEEE\s+\S+)/,
          '\1; \2'
        )

        # Strip ":YYYY" from IEC numbers when an Edition clause follows — the
        # IEEE parser's number rule doesn't accept the colon-year form, but
        # the year is preserved in the "Edition N.M YYYY-MM" suffix.
        # (issue #202)
        cleaned = cleaned.gsub(
          /^(IEC\s+\d+(?:-\d+)?):\d{4}(\s+(?:First\s+)?[Ee]dition\s+\d+(?:\.\d+)?\s+\d{4}-\d{2})/,
          '\1\2'
        )

        # NEW Phase 1 (Session 141): Remove literal trademark symbol
        # "C57.110™-2018" → "C57.110-2018"
        cleaned = cleaned.gsub(/™/, "")

        # NEW Phase 1 (Session 141): Fix specific year typo
        # "19969" → "1969" (very specific pattern, won't affect other text)
        cleaned = cleaned.gsub(/\b19969\b/, "1969")

        # NEW Session 169: Fix comma typo in 802.3 series numbers
        # "802.3ch-2020,802.3ca-2020" → "802.3ch-2020, 802.3ca-2020"
        # Very specific: 4 digits, comma, 3 digits (likely 802.3xx typo)
        cleaned = cleaned.gsub(/(\d{4}),(\d{3})/, '\1, \2')

        # NEW Session 169: Fix /lNT typo (lowercase L as 1)
        # "1003.1/2003.l/lNT" → "1003.1/2003.1/INT"
        cleaned = cleaned.gsub(/\/lNT\b/, "/INT")
        cleaned = cleaned.gsub(".l/", ".1/") # Also fix .l/ -> .1/

        # NEW Session 169: Fix I99O typo (letter I and O instead of digits)
        # "IEEE 1076-CONC-I99O" → "IEEE 1076-CONC-1990"
        cleaned = cleaned.gsub(/\bI99O\b/, "1990")

        # NEW: Fix common typos (Category 9)
        cleaned = cleaned.gsub(/^EEE /, "IEEE ")

        # NEW Session 170: Additional safe typo fixes
        # Fix "I EEE" (space between I and EEE)
        cleaned = cleaned.gsub(/^I EEE /, "IEEE ")

        # Fix "lEEE" (lowercase L instead of I)
        cleaned = cleaned.gsub(/^lEEE /, "IEEE ")

        # Fix missing closing parenthesis at end only (very conservative)
        # Only if there's exactly one more opening than closing paren
        open_count = cleaned.count("(")
        close_count = cleaned.count(")")
        if open_count == close_count + 1 && !cleaned.end_with?(")")
          cleaned = "#{cleaned})"
        end

        # NEW Phase 1: Remove trailing commas/colons and text
        cleaned = cleaned.gsub(/,\s*Standard\s*$/, "") # ", Standard" at end
        cleaned = cleaned.gsub(/[,:]\s*$/, "") # Trailing comma/colon
        cleaned = cleaned.gsub(/,\s+and\s+IEEE\s+Std\s/, " and ") # Handle "IEEE Std and Std" case

        # Enhanced: Fix unbalanced parentheses comprehensively
        # Handle three cases: missing closing, extra opening, nested unbalanced
        open_count = cleaned.count("(")
        close_count = cleaned.count(")")

        if open_count > close_count
          # More opening than closing - add closing parens at end
          # This handles both simple missing and nested unbalanced cases
          missing = open_count - close_count
          cleaned = cleaned + (")" * missing)
        elsif close_count > open_count
          # More closing than opening - remove extra closing from end
          # Very conservative: only remove trailing excess closing parens
          extra = close_count - open_count
          cleaned = cleaned.sub(/\){#{extra}}$/, "")
        end

        # === SESSION 173: TODO.IEEE-MUST-DO.txt Preprocessing Enhancements ===

        # Part A: Simple Normalizations (Lines 13, 16, 32-35, 36, 39-41 from TODO)

        # 1. Missing dash before year: "802.16g 2007" → "802.16g-2007"
        # But be careful not to affect month names (already have space)
        # Only apply if: digit + space + 4-digit year (and not after a month name)
        cleaned = cleaned.gsub(/(\d)\s+(\d{4})(?=\s*\(|\s*$)/, '\1-\2')

        # 2. Space-dash-space before year: "802.1ag - 2007" → "802.1ag-2007"
        # This is distinct from " - " in titles, targets space-dash-space-year pattern
        cleaned = cleaned.gsub(/\s+-\s+(\d{4})\b/, '-\1')

        # 3. Add missing "Std" after IEEE: "IEEE 1070-1995" → "IEEE Std 1070-1995"
        # Only at start of string, IEEE + space + digit
        cleaned = cleaned.gsub(/^IEEE\s+(?!Std\b)(\d)/, 'IEEE Std \1')

        # 3.5. Convert "IEEE No." to "IEEE Std": "IEEE No. 264-1968" → "IEEE Std 264-1968"
        # NOTE: Do NOT convert AIEE No - AIEE uses "No" as standard format
        cleaned = cleaned.gsub(/^IEEE\s+No\.\s*/, "IEEE Std ")
        cleaned = cleaned.gsub(/^IEEE\s+No\s/, "IEEE Std ")
        # Skip AIEE No conversion - AIEE preserves "No" format

        # 4. Space before slash in dual published: "262-1973 /ANSI" → "262-1973/ANSI"
        cleaned = cleaned.gsub(/\s+\//, "/")

        # 5. Comma before Edition: ", 1998 Edition" → "-1998"
        # Normalize to standard year format for parser
        cleaned = cleaned.gsub(/,\s+(\d{4})\s+Edition/, '-\1')

        # 6. ISO/IEC spacing: "ISO/IEC15802" → "ISO/IEC 15802"
        # Add space between publisher prefix and number
        cleaned = cleaned.gsub(/(ISO\/IEC)(\d)/, '\1 \2')

        # Part B: Publisher Order (Line 38 from TODO)

        # Fix wrong publisher order: "IEEE Std ANSI/IEEE" → "ANSI/IEEE Std"
        # This handles cases where IEEE Std appears before ANSI/IEEE publisher
        cleaned = cleaned.gsub(/^IEEE\s+Std\s+(ANSI\/IEEE)/, '\1 Std')

        # Part C: Dual Published Formats (Lines 8, 19 from TODO)

        # 1. Semicolon to parenthetical for dual published (MultiLabeledIdentifier)
        # "IEEE Std 120-1955; ASME PTC 19.6-1955" → "IEEE Std 120-1955 (ASME PTC 19.6-1955)"
        # Only if semicolon + space + organization abbreviation (capital letters)
        if cleaned.match?(/;\s+[A-Z]{2,}/)
          cleaned = cleaned.sub(/;\s+([A-Z][^;]+)$/, ' (\1)')
        end

        # === SESSION 174: Additional TODO.IEEE-MUST-DO.txt Preprocessing ===

        # Part A: Edition Abbreviation Normalization (Lines 10-11)
        # Pattern: ", 1999 Edn. (Reaff 2003)" → "-1999 (R2003)"
        # Normalize both the Edition abbreviation and the Reaffirmed format
        cleaned = cleaned.gsub(/,\s+(\d{4})\s+Edn\.\s+\(Reaff\s+(\d{4})\)/,
                               '-\1 (R\2)')
        # Also handle without initial comma (might occur in relationships)
        cleaned = cleaned.gsub(/(\d{4})\s+Edn\.\s+\(Reaff\s+(\d{4})\)/,
                               '\1 (R\2)')

        # Part B: IRE Parenthetical Split (Line 9)
        # Pattern: "(Reaffirmed 1980, 56 IRE 28.S2)" → "(R1980) (56 IRE 28.S2)"
        # Split nested reaffirmation + IRE reference into two parentheticals
        cleaned = cleaned.gsub(/\(Reaffirmed\s+(\d{4}),\s+(\d+\s+IRE[^)]+)\)/,
                               '(R\1) (\2)')

        # Part C: Slash to Parenthetical (Line 37)
        # Pattern: "number-year/ANSI identifier" → "number-year (ANSI identifier)"
        # Only convert if slash is followed by ANSI and NOT a relationship keyword
        # Look ahead to ensure we're at end of main identifier (before paren or end of string)
        cleaned = cleaned.gsub(%r{(\d{4})/ANSI\s+([^(]+)(?=\s*\(|$)},
                               '\1 (ANSI \2)')

        # Part D: ISO/IEC TR Spacing (Line 40)
        # Pattern: "ISO/IEC TR11802" → "ISO/IEC TR 11802"
        # Add space after TR when directly followed by digit
        cleaned = cleaned.gsub(/(ISO\/IEC\s+TR)(\d)/, '\1 \2')
        # === SESSION 178: AIEE Dual Numbers Expansion (Line 45) ===

        # Part E: AIEE "Nos X and Y" Expansion
        # Pattern: "AIEE Nos 72 and 73 - 1932" → "AIEE No 72-1932 and AIEE No 73-1932"
        # Expands dual AIEE numbers to separate identifiers with shared year
        if cleaned.match?(/AIEE\s+Nos\s+(\d+)\s+and\s+(\d+)\s+-\s+(\d{4})/)
          cleaned = cleaned.sub(/AIEE\s+Nos\s+(\d+)\s+and\s+(\d+)\s+-\s+(\d{4})/) do
            first_num = $1
            second_num = $2
            year = $3
            "AIEE No #{first_num}-#{year} and AIEE No #{second_num}-#{year}"
          end
        end

        # === SESSION 222: TODO.IEEE-MUST-FIX-IDs.txt Comprehensive Fixes ===

        # Part A: Typo Fixes
        # 1. "Stad" -> "Std" (typo)
        cleaned = cleaned.gsub(/\bStad\b/, "Std")

        # 2. Lowercase "std" -> "Std" when after IEEE/ANSI publishers
        cleaned = cleaned.gsub(/\b(IEEE|ANSI|AIEE)\s+std\b/, '\1 Std')

        # Part B: Symbol Normalization
        # 3. Additional (TM) patterns - strip them out
        cleaned = cleaned.gsub("(TM)", "")

        # Part C: Year-first format normalization
        # 4. Pattern "62704-4/D4, 2020" -> "IEEE P62704-4/D4, 2020"
        # Only if starts with digits-dash-digits/D pattern
        if cleaned.match?(/^(\d+[-.]\d+)\/D\d+/)
          cleaned = "IEEE P#{cleaned}"
        end

        # Part E: Relationship Text Normalization
        # 6. "Proposed Revision of" -> "Revision of"
        cleaned = cleaned.gsub("Proposed Revision of", "Revision of")

        # 7. "ammended" typo -> "amended"
        cleaned = cleaned.gsub(/\bammended\b/i, "amended")

        # Part F: Trailing Characters After Special Patterns
        # 8. Remove trailing periods after /INT, /Cor, etc.
        cleaned = cleaned.gsub(/(\/INT|\/Cor\s+\d+-\d{4})\./, '\1')

        # Part G: Conformance Pattern Spacing
        # 9. Fix spacing in "/Conformance" patterns WITHOUT year (malformed only)
        # "1904.1(TM)/Conformance02" -> "1904.1 /Conformance02" (space before slash)
        # BUT: DO NOT touch valid patterns like "802.16/Conformance01-2003" (with year)
        # Use positive check for year suffix to exclude valid patterns
        # Actually, this preprocessing is breaking valid patterns - just remove it entirely
        # The parser can handle both "6/Conformance01-2003" and "6 /Conformance02" formats

        # Part H: Edition Text After /INT
        # 10. Handle ", Month YYYY Edition" after /INT by converting to month-year format
        # "1003.1/INT, March 1994 Edition" -> "1003.1/INT, March 1994"
        cleaned = cleaned.gsub(/(\/INT),\s+([A-Z][a-z]+)\s+(\d{4})\s+Edition/,
                               '\1, \2 \3')

        # Part I: Handle "Ed." abbreviation
        # 11. "Dec. 1994 Ed." -> "Dec. 1994"
        cleaned = cleaned.gsub(/\s+Ed\.\s*$/, "")

        # === PHASE 2: High-impact preprocessing for fixture failures ===

        # Quick wins from SESSION 224 (must come before more complex fixes)

        # Remove period after "Std": "IEEE Std." -> "IEEE Std"
        cleaned = cleaned.gsub(/\bStd\.\s+/, "Std ")


        # Title portion removal after year: "YYYY - IEEE Standard for..."
        cleaned = cleaned.gsub(
          /(\d{4})(\s+\([^)]+\))?\s+-\s+IEEE\s+Standard\s+for.*$/, '\1\2'
        )

        # Fix 2A: "IEEE PC" prefix -> "IEEE Std PC" or "IEEE P" treatment
        # "IEEE PC37.20.9/D7.3A" -> needs to parse as IEEE project draft
        # Strategy: Add "Std" after "IEEE" when followed by "PC" to route to standard pattern
        # Actually, the issue is the number rule consumes "PC37" as P + C37.
        # Better: normalize "IEEE PC" to "IEEE Std PC" so it hits the standard identifier path
        cleaned = cleaned.gsub(/^IEEE\s+PC(\d)/, 'IEEE Std PC\1')
        cleaned = cleaned.gsub(/^IEEE\s+Unapproved\s+Draft\s+Std\s+PC(\d)/,
                               'IEEE Unapproved Draft Std PC\1')

        # Fix 2B: "IEEE P" without "Std"/"Draft" prefix
        # ieee_p_identifier rule handles these directly - no preprocessing needed
        # Only handle "IEEE P" followed by "and ASHRAE" (copub case)
        cleaned = cleaned.gsub(/^IEEE\s+P(\d+)\s+and\s+ASHRAE/,
                               'IEEE Std P\1 and ASHRAE')

        # Fix 2C: "ISO/IEC XXXX-YYYY: Title" -> strip title after colon for ISO/IEC published standards
        # These are ISO-format identifiers with IEEE adoption, strip the title
        cleaned = cleaned.gsub(/^(ISO\/IEC \d+[-.]\d+-\d{4}):.*$/, '\1')
        cleaned = cleaned.gsub(/^(ISO\/IEC \d+-\d{4}):.*$/, '\1')

        # Fix 2D: "ISO/IEC XXXX : YYYY" -> normalize spacing around colon
        cleaned = cleaned.gsub(/^(ISO\/IEC \d+[-.]\d*)\s*:\s*(\d{4})/, '\1:\2')
        cleaned = cleaned.gsub(/^(ISO\/IEC \d+)\s*:\s*(\d{4})/, '\1:\2')

        # Fix 2G: "IEC/IEEE PXXX_D5" -> underscore to slash
        cleaned = cleaned.gsub(/^(IEC\/IEEE P[\w.-]+)_D/, '\1/D')

        # Fix 2H: "IEC XXXX First edition YYYY-MM; IEEE NNNN" -> normalize semicolon
        # Already handled by earlier semicolon normalization

        # (Fix 2I removed: "IEEE/ISO/IEC PXXX/…" is no longer rewritten to
        # ISO-first — the printed publisher order is the organization's
        # perspective (pubid#469) and the joint P-form rule parses it as
        # printed.)

        # Fix 2J: "IEEE/IEC PXXX D5" -> normalize space to slash before D
        cleaned = cleaned.gsub(/^(IEEE\/IEC P[\w.-]+)\s+D(\d)/, '\1/D\2')
        cleaned = cleaned.gsub(
          /^(IEEE\/IEC P[\w.-]+)\s+(CDV|FDIS|CD|DIS|ED\d)/, '\1/\2'
        )

        # Fix 2K: "ISO /IEC/IEEE" -> fix space before slash
        cleaned = cleaned.gsub(/^ISO\s+\/IEC\/IEEE/, "ISO/IEC/IEEE")
        cleaned = cleaned.gsub(/^ISO\s+\/IEC/, "ISO/IEC")

        # Fix 2L: "IS0" typo (letter O instead of digit 0)
        cleaned = cleaned.gsub(/^IS0\//, "ISO/")

        # Fix 2M: "IEEE-P15026-3-DIS-January 2015" -> dash-separated format
        # Normalize to "ISO/IEC/IEEE P15026-3/DIS, January 2015"
        cleaned = cleaned.gsub(/^IEEE-P(\d+)-(\d+)-DIS-(.*)/,
                               'ISO/IEC/IEEE P\1-\2/DIS, \3')

        # Fix 2N: "IEEE/CSA P844.1/293.1/D2" -> normalize CSA dual numbering
        cleaned = cleaned.gsub(/^IEEE\/CSA\s+(P[\d.]+)\/([\d.]+)\/D(\d+)/,
                               'IEEE/CSA \1/D\3')

        # Fix 2O: "IEEE Approved Draft Std P" -> normalize spacing
        cleaned = cleaned.gsub(/^IEEE\s+Approved\s+Draft\s+Std\s+(P\d)/,
                               'IEEE Approved Draft Std \1')
        # Fix: "IEEE Approved Draft Std P1234 / D12" -> remove space before slash
        cleaned = cleaned.gsub(/^(IEEE Approved Draft Std P[\w.-]+)\s+\/\s*D/,
                               '\1/D')

        # Fix 2P: "IEEE/EIA" -> normalize (parser handles IEEE/EIA via copublisher)
        # Already works - no fix needed

        # Fix 2Q: AIEE format variations
        # "AIEE No.1C-1954" -> "AIEE No. 1C-1954" (add space after No.)
        cleaned = cleaned.gsub(/^AIEE\s+No\.\s*(\d)/, 'AIEE No. \1')
        # "AIEE no 700-1945" -> "AIEE No 700-1945" (capitalize)
        cleaned = cleaned.gsub(/^AIEE\s+no\s/, "AIEE No ")
        # "AIEE Std No. 800" -> "AIEE Standard No 800" (normalize type word)
        cleaned = cleaned.gsub(/^AIEE\s+Std\s+No\.\s*/, "AIEE Standard No ")
        # "AIEE No 750.1-1960" -> handled by AIEE parser if decimal support added

        # Fix 2R: "IEEE PSI 10/D2" -> normalize to "IEEE/ASTM PSI 10/D2"
        cleaned = cleaned.gsub(/^IEEE\s+PSI\s+(\d)/, 'IEEE/ASTM PSI \1')

        # Fix 2S: "IEEE/IEC P62271-111/PC37.60_D5" -> normalize
        cleaned = cleaned.gsub(/^(IEEE\/IEC P[\d.-]+\/PC[\d.]+)_D/, '\1/D')

        # Fix 2T: "IEC P62271-111/IEEE PC37.60_D5" -> normalize to IEC/IEEE format
        cleaned = cleaned.gsub(/^IEC\s+(P[\d.-]+)\/IEEE\s+(PC[\d.]+)_D/,
                               'IEC/IEEE \2/D')

        # Fix 2U: "IEC/IEC P" -> "IEC/IEEE P" (typo)
        cleaned = cleaned.gsub(/^IEC\/IEC\s+(P\d)/, 'IEC/IEEE \1')

        # Fix 2V: "NACE SPXXXX-YYYY/IEEE Std NNNN-YYYY" -> normalize slash to parenthetical
        cleaned = cleaned.gsub(/^(NACE\s+SP\d+-\d+)\/(IEEE\s+Std\s+\d+-\d+)$/,
                               '\1 (\2)')

        # Fix 2W: "IEEE Std 802.11g-2003 (Amendment to IEEE Std 802.11, 1999 Edn. (Reaff 2003) as amended by"
        # This is a complex relationship - strip the parenthetical if too complex
        # Let the parser handle it but fix "Edn." to "Edition"
        cleaned = cleaned.gsub("Edn.", "Edition")

        # Fix 2X: "IEEE-P15026-3-DIS" format -> normalize
        # Already handled by Fix 2M

        # Fix 2Y: "P1635/D10/ASHARE 21/D10" -> fix ASHARE typo to ASHRAE
        cleaned = cleaned.gsub("ASHARE", "ASHRAE")

        # Fix 2Z: "PC37.30.2/D043 Rev 18" -> normalize draft version with Rev
        # "PC57-15 D2.0" -> normalize to "P57-15/D2.0"
        cleaned = cleaned.gsub(/^PC(\d)/, 'P\1')

        # Fix 2AA: "IEEE/ISO/IEC 8802-1Q-2020/Amd31-2021" -> normalize
        cleaned = cleaned.gsub(/^IEEE\/ISO\/IEC\s+(8802[\w.-]+)/,
                               'ISO/IEC/IEEE \1')

        # Fix 2AB: "IEEE C57.139/D14June 2010" -> add missing space
        cleaned = cleaned.gsub(
          /^(IEEE\s+C?\d[\d.]*\/D\d+)([A-Z][a-z]+\s+\d{4})/, '\1, \2'
        )

        # Fix 2AC: "IEEE Std: Title" -> strip colon and title (ANSI/IEEE Std: )
        cleaned = cleaned.gsub(/^(ANSI\/IEEE Std):\s+.*$/, '\1')

        # Fix 2AD: "IEEE 1076 IEC 61691-1-1 First edition 2004-10" -> semicolon format
        cleaned = cleaned.gsub(
          /^(IEEE\s+[\d.]+)\s+(IEC\s+\d+[-\d]*\s+.*edition\s+\d{4}-\d{2})$/i, '\1; \2'
        )

        # Fix 2AE: "IEEE No 29-1941 / ASA C77.1-1943" -> normalize to IEEE Std format
        cleaned = cleaned.gsub(/^IEEE\s+No\s+(\d+-\d+)\s+\/\s+ASA\s+(.*)/,
                               'IEEE Std \1 (ASA \2)')

        # Fix 2AF: "IEEE Std 1003.1/2003.l/lNT" -> fix typos
        # .l -> .1 and lNT -> INT handled by existing fixes

        cleaned
      end

      def self.parse(string)
        new.parse(normalize_input(string))
      end
    end
  end
end
