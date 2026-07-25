# frozen_string_literal: true

require "parslet"

module Pubid
  module Ieee
    # Parser class for IEEE identifiers
    # Single Responsibility: Parsing IEEE identifier syntax
    # Note: IEEE is extremely complex with many edge cases
    class Parser < Parslet::Parser
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
          str("IEC") | str("ISO") | str("ASTM") | str("CSA") | str("ASME") |
          str("NACE") | str("NSF") | str("ASHRAE") | str("NCTA") | str("AESC") |
          str("EIA") # NEW Session 224: Add EIA support
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

      # Document number - support letters and digits, with optional prefix P
      # Complex multi-part numbers like P11073-10404-10419 should be fully captured
      # But simple cases like "623-1976" should not consume the dash before year
      rule(:number) do
        (str("P").maybe >>
         (digits | upper).repeat(1) >> # The first component must be at least one digit
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
        (str("Active Unapproved") | str("Unapproved") | str("Approved")) >> space
      end

      rule(:draft_prefix) do
        space? >> (str("/") | str("_") | dash | space)
      end

      rule(:draft_version) do
        # Enhanced to handle multiple draft notation patterns
        # D is optional to handle /08 style drafts (e.g., IEEE P1052/08)
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
          (((space? >> comma >> space?) | space) >> month_name.as(:month) >>
          (
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
         draft_date.maybe).as(:draft)
      end

      # Edition - enhanced to support IEC formats like "Edition 1.0 2015-03"
      rule(:edition) do
        (comma >> year_digits.as(:year) >> str(" Edition")) |
          ((space | dash) >> str("Edition ") >>
           (digits >> dot >> digits).as(:edition) >>
           (space | str(" - ")) >>
           year_digits.as(:year) >>
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

      # Redline
      rule(:redline) do
        str(" - Redline").as(:redline)
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
        (space.maybe >> str("(") >> # Make space before '(' optional
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
          match("[^\n]").repeat(1).as(:content)
      end

      # Joint development patterns (ISO/IEC/IEEE in either IEEE or ISO format)
      rule(:joint_development_ieee_format) do
        # ISO/IEC/IEEE P26511/D8-2018 or ISO/IEEE P1003.1-2008 or IEC/IEEE P62582-1-2011
        # ALSO handle: IEC/IEEE P60780-323, CDV1 2014 (comma before stage code)
        # ALSO handle: IEEE/CSA P844.1/293.1/D2 (CSA dual numbering)
        (str("ISO/IEC/IEEE") | str("ISO/IEEE") | str("IEC/IEEE") | str("IEEE/CSA")).as(:joint_publishers) >>
          space >>
          str("P") >> # P indicates IEEE-led
          digits.as(:number) >>
          ((dot | dash) >> digits.as(:part)).maybe >> # Optional part like .1 or -1
          # CSA dual numbering: /293.1 (second number)
          (slash >> digits >> (dot >> digits).maybe >> (dash >> digits.as(:draft_version)).maybe).maybe >>
          (
            # Variant 1: /D8 notation (original)
            (slash >> str("D") >> digits.as(:draft_version)) |
            # Variant 2: , CDV1 notation (comma before stage code)
            (comma >> (str("CDV") | str("FDIS") | str("CD") | str("DIS")).as(:iec_stage) >> digits.maybe.as(:stage_iteration))
          ).maybe >>
          ((dash >> year_digits.as(:year)) | # Either -YEAR
           (comma.maybe >> space >> month_name.as(:month) >> space.maybe >> year_digits.as(:year))).maybe # Or Month YEAR (with optional comma)
      end

      rule(:joint_development_iso_format) do
        # ISO/IEC/IEEE FDIS 26511:2018 (ISO-led format)
        (str("ISO/IEC/IEEE") | str("ISO/IEEE") | str("IEC/IEEE")).as(:joint_publishers) >>
          space >>
          # ISO stage codes
          (str("FDIS") | str("DIS") | str("CD") | str("WD") | str("PWI") | str("NP")).as(:iso_stage) >>
          space >>
          digits.as(:number) >>
          ((dot | dash) >> digits.as(:part)).maybe >> # Optional part
          (str(":") >> year_digits.as(:year)).maybe
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
      rule(:ieee_p_identifier) do
        (str("IEEE").as(:publisher) >> space).maybe >> # Make IEEE prefix optional
          str("P") >> space.maybe >> # Make space after P optional
          number >>
          (part_subpart_year | edition).maybe >>
          # Pattern for /08 style drafts (digits without D prefix) - MUST come before corrigendum
          (slash >> digits.as(:draft_version)).as(:digit_draft).maybe >>
          # FDIS and other ISO stage codes without D prefix (Pattern 3)
          fdraft.maybe >>
          # Enhanced: Accept both comma and space before month/year
          ((comma | space) >> month_name.as(:month) >> space >> year_digits.as(:year)).maybe >>
          corrigendum.maybe >>
          draft.maybe >>
          # ALSO accept month/year after draft (some patterns like /DX, Month YEAR)
          ((comma | space) >> month_name.as(:month) >> space >> year_digits.as(:year)).maybe >>
          parenthetical.maybe
      end

      # ANSI P pattern: "ANSI PN42.34-D9a, 2015" OR "ANSI P1234/D5"
      rule(:ansi_p_identifier) do
        str("ANSI").as(:publisher) >> space >>
          str("P") >> space.maybe >> # Make space after P optional
          number >>
          (part_subpart_year | edition).maybe >>
          # Enhanced: Accept both comma and space before month/year
          ((comma | space) >> month_name.as(:month) >> space >> year_digits.as(:year)).maybe >>
          corrigendum.maybe >>
          draft.maybe >>
          # ALSO accept month/year after draft
          ((comma | space) >> month_name.as(:month) >> space >> year_digits.as(:year)).maybe >>
          # Accept bare year after draft: ", 2015"
          ((comma | space) >> year_digits.as(:year)).maybe >>
          parenthetical.maybe
      end

      # IEEE Draft P pattern: "IEEE Draft P802.11..." OR "Draft P802.11..." (IEEE prefix optional)
      rule(:ieee_draft_p_identifier) do
        (str("IEEE").as(:publisher) >> space).maybe >> # Make IEEE prefix optional
          str("Draft") >> space >>
          str("P") >>
          number >>
          (part_subpart_year | edition).maybe >>
          # Enhanced: Accept month/year after draft number
          (space >> month_name.as(:month) >> space >> year_digits.as(:year)).maybe >>
          draft.maybe >>
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
          (str("National Electrical Safety Code") >> str(",") >> space >> str("C2-"))
        ).present? >>
          # Delegate to NESC parser if pattern detected
          Nesc::Parser.new.nesc_identifier.as(:nesc)
      end

      # IEEE/ASTM SI/PSI (Système International) patterns
      # SI = Published metric system standard
      # PSI = Proposed SI (draft)
      rule(:ieee_astm_si_psi) do
        str("IEEE/ASTM").as(:publishers) >>
          space >>
          (str("PSI") | str("SI")).as(:si_type) >>
          space >>
          digits.as(:number) >>
          # Draft notation for PSI (e.g., /D2, /D3)
          (slash >> str("D") >> digits.as(:draft_version)).maybe >>
          # Year with optional month
          (
            # Format: ", Month Year"
            (comma >> month_name.as(:month) >> space >> year_digits.as(:year)) |
            # Format: "-YEAR"
            (dash >> year_digits.as(:year))
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
            # Format 1: C22.2 No. 293.1-17 (with NO.)
            (str("C") >> digit.repeat(2) >> dot >> digit >> space >> str("No") >> dot >> space >>
             match("[0-9.]").repeat(1) >> (dash | str(":")) >> digit.repeat(2)) |
            # Format 2: C293.2-17 (without NO., dash year)
            (str("C") >> match("[0-9.]").repeat(1) >> dash >> digit.repeat(2)) |
            # Format 3: C22.2 No. 293.3:19 (with NO., colon year)
            (str("C") >> digit.repeat(2) >> dot >> digit >> space >> str("No") >> dot >> space >>
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
          corrigendum_identifier | # NEW: Try corrigendum before generic patterns
          interpretation_identifier | # NEW: Try interpretation identifier before generic patterns
          conformance_identifier | # NEW: Try conformance identifier before generic patterns
          joint_development_ieee_format |
          joint_development_iso_format |
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
          # Enhanced: Accept both comma and space before month/year
          ((comma | space) >> month_name.as(:month) >> space >> year_digits.as(:year)).maybe >>
          edition.maybe >>
          parenthetical.maybe >>  # REVERT: Back to single parenthetical
          book_nickname.maybe >>  # NEW: Add book nickname support
          redline.maybe >>
          title_portion.maybe >>
          approved_draft_suffix.maybe) |
          no_prefix_ieee # NEW: Try no-prefix patterns last (lowest priority)
      end

      root(:identifier)

      def self.parse(string)
        # Strip .pdf extension if present (Pattern 3: File Extensions)
        cleaned = string.sub(/\.pdf$/i, "")

        # Note: IEC and ANSI identifiers are NOT filtered here because they can have
        # IEEE co-publication or adoption. The Base.parse method handles determining
        # which standards are actually IEEE-related.
        # ISO-only standards are still filtered as they have separate handling.

        # Pattern 3: Replace underscore before ISO stage codes with slash
        # These are joint development drafts that use underscore instead of slash
        cleaned = cleaned.gsub(/_(FDIS|CDV|CD|DIS|WD|PWI|NP)/, '/\1')

        # NEW: Normalize multiple spaces to single space
        # No valid IEEE identifier pattern needs more than 1 space
        cleaned = cleaned.gsub(/\s+/, " ")

        # NEW Session 171: CONSERVATIVE data quality fixes for TODO.IEEE-MUST-DO.txt
        # Only fix clear typos: space before dash + 4-digit year, OR dash + space + 4-digit year
        # Do NOT touch " - " (space-dash-space) which is valid formatting
        cleaned = cleaned.gsub(/(\d)\s+-(\d{4})\b/, '\1-\2')  # "C37.101 -2006" → "C37.101-2006"
        cleaned = cleaned.gsub(/(\d)-\s+(\d{4})\b/, '\1-\2')  # "C62.35- 2010" → "C62.35-2010"

        # NEW Session 171: HTML entity for en dash (&#x2013;)
        # ONLY convert if not already followed by a dash (avoid creating --)
        cleaned = cleaned.gsub(/&#x2013;(?!-)/, "-")  # En dash → regular hyphen (if not followed by dash)
        cleaned = cleaned.gsub("&#x2013;-", "-")      # En-dash-dash → single dash

        # NEW Session 171: Remove wrong ! prefix
        cleaned = cleaned.gsub(/^!IEEE /, "IEEE ")

        # NEW Session 171: Fix "IEEE/ ASTM" spacing (extra space after slash)
        cleaned = cleaned.gsub("IEEE/ ASTM", "IEEE/ASTM")

        # NEW Phase 1: Handle HTML entities comprehensively
        cleaned = cleaned.gsub("&#x2122;", "™") # Trademark symbol
        cleaned = cleaned.gsub("&#x2019;", "'") # Smart apostrophe
        cleaned = cleaned.gsub("&amp;amp;", "&")   # Double-encoded ampersand
        cleaned = cleaned.gsub("&amp;", "&")       # Single-encoded ampersand

        # NEW: Wrap P&V notation in parentheses (Paper & Video, etc.)
        # Pattern: "IEEE Std 500-1984 P&V" → "IEEE Std 500-1984 (P&V)"
        cleaned = cleaned.gsub(/\s+(P&V)\s*$/, ' (\1)')

        # NEW Phase 1: Fix number spacing issues (e.g., "C57.1 2.25" → "C57.12.25")
        # This handles cases where a space appears in the middle of a number
        cleaned = cleaned.gsub(/(\d+\.\d+)\s+(\d+\.)/, '\1\2')

        # NEW Phase 1: Fix year spacing issues (e.g., "1 996" → "1996")
        # Remove spaces within 4-digit years
        cleaned = cleaned.gsub(/\b(1|2)\s+(\d{3})\b/, '\1\2')

        # NEW: Fix month+year spacing (e.g., "March2016" → "March 2016")
        # Add space between month name and 4-digit year when they're concatenated
        cleaned = cleaned.gsub(
          /\b(January|February|March|April|May|June|July|August|September|October|November|December)(\d{4})\b/, '\1 \2'
        )
        # Also handle abbreviated months
        cleaned = cleaned.gsub(
          /\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)(\d{4})\b/, '\1 \2'
        )

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

        # Part D: Suffix Normalization
        # 5. "/Preprint" -> remove (data quality - not standard suffix)
        cleaned = cleaned.gsub(/\/Preprint\b/, "")

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

        # Redline Suffix Removal: " - Redline" at end
        cleaned = cleaned.gsub(/\s+-\s+Redline\b.*$/, "")

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

        # Fix 2I: "IEEE/ISO/IEC PXXX/DIS" -> normalize to "ISO/IEC/IEEE PXXX/DIS"
        cleaned = cleaned.gsub(/^IEEE\/ISO\/IEC\s+(P[\w.-]+)/,
                               'ISO/IEC/IEEE \1')
        cleaned = cleaned.gsub(/^IEEE\/IEC\/ISO\s+(P[\w.-]+)/,
                               'IEC/ISO/IEEE \1')

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

        new.parse(cleaned)
      end
    end
  end
end
