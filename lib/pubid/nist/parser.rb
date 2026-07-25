# frozen_string_literal: true

require "parslet"

module Pubid
  module Nist
    # Parser class for NIST identifiers
    # Single Responsibility: Parsing NIST identifier syntax
    class Parser < Parslet::Parser

      # Class-level parse method with preprocessing.
      # Delegates all string normalization to Nist::Preprocessor, then
      # feeds the cleaned string to the Parslet grammar and stamps the
      # detected format onto the parse tree.
      def self.class_parse_with_preprocessing(input)
        result = Preprocessor.new(input).call
        parsed = new.parse(result.cleaned)

        if parsed.is_a?(Hash)
          parsed.merge(parsed_format: result.format)
        elsif parsed.is_a?(Array)
          merged = parsed.each_with_object({}) do |hash, acc|
            next acc unless hash.is_a?(Hash)

            acc.merge!(hash)
          end
          merged.merge(parsed_format: result.format)
        else
          parsed
        end
      end

      # Basic building blocks
      rule(:space) { str(" ") }
      rule(:dot) { str(".") }
      rule(:dash) { str("-") }
      rule(:slash) { str("/") }
      rule(:digit) { match("[0-9]") }
      rule(:digits) { digit.repeat(1) }
      rule(:letter) { match("[A-Za-z]") }
      rule(:upper_letter) { match("[A-Z]") }
      rule(:lower_letter) { match("[a-z]") }

      # Hash prefix for machine-readable formats
      rule(:hash_prefix) { str("#") }

      # Month abbreviations
      rule(:month_abbrev) do
        str("January") | str("February") | str("March") | str("April") |
          str("May") | str("June") | str("July") | str("August") |
          str("September") | str("October") | str("November") | str("December") |
          str("Jan") | str("Feb") | str("Mar") | str("Apr") |
          str("Jun") | str("Jul") | str("Aug") | str("Sep") | str("Oct") | str("Nov") | str("Dec")
      end

      # Language codes for translations - 2-4 letter codes
      # Supports: " spa", "(spa)", ".spa" (MR format)
      rule(:language_code) do
        ((space | dot).maybe >> (str("es") | str("pt") | str("chi") | str("viet") | str("port") | str("esp") |
         match("[a-z]").repeat(2, 4))).as(:translation)
      end

      # Stage ID: i (initial), f (final), 1-9 (numbered iterations)
      rule(:stage_id) do
        str("i") | str("I") | str("f") | str("F") |
          str("1") | str("2") | str("3") | str("4") | str("5") |
          str("6") | str("7") | str("8") | str("9")
      end

      # Stage type: pd (public draft), wd (work-in-progress), prd (preliminary)
      rule(:stage_type) do
        str("pd") | str("PD") | str("wd") | str("WD") | str("prd") | str("PRD")
      end

      # Old style stage: (IPD), (FPD), (2PD) - parenthetical at document start
      rule(:old_stage) do
        str("(") >> (stage_id.as(:stage_id) >> stage_type.as(:stage_type)).as(:stage) >> str(")")
      end

      # New style stage: " ipd", ".ipd" - inline at document end
      rule(:new_stage) do
        (space | dot) >> (stage_id.as(:stage_id) >> stage_type.as(:stage_type)).as(:stage)
      end

      # Publisher
      rule(:publisher) do
        (str("NBS") | str("NIST")).as(:publisher)
      end

      # Compound series (include publisher in series name) - must be checked FIRST
      rule(:compound_series) do
        (
          # Longest patterns first to avoid partial matches
          str("NBS BRPD-CRPL-D") | str("NBS CRPL-F-A") | str("NBS CRPL-F-B") |
          str("NBS CS-E") | str("CSRC Building Block") | str("CSRC Use Case") | str("CSRC Book") |
          str("ITL Bulletin") | str("NSRDS-NBS") |
          # NBS and NIST specific patterns that conflict with simple series
          # CRITICAL: Put longer patterns before shorter to avoid partial matches!
          str("NIST LCIRC") | str("NBS LCIRC") | str("NIST.LCIRC") | str("NBS.LCIRC") | str("NBS RPT") |
          str("NIST PS") | str("NIST DCI") | str("NIST Other") |
          str("NISTPUB") |
          str("NBS CSM") | str("NBS CIRC") | str("NBS.CRPL") | str("NBS CRPL") | str("NBS CS") |
          str("NBS CIS") | str("NBS HR") | str("NBS IRPL") | str("NBS IP") | str("NBS PS") |
          str("NBS BH")
        ).as(:series)
      end

      # Simple series (no publisher prefix)
      rule(:simple_series) do
        (
          str("AMS") | str("VTS") | # NEW - Added for NIST AMS and VTS series
          str("BSS") | str("BMS") | str("BH") |
          str("FIPS") | str("GCR") | str("HB") | str("MONO") |
          str("MP") | str("NCSTAR") | str("NSRDS") | str("IR") |
          str("SP") | str("TN") | str("CSWP") |
          str("AI") | str("CIRC") | str("CS") | str("CSM") |
          str("CRPL") | str("LCIRC") | str("OWMWP") | str("PC") | str("RPT") |
          str("SIBS") | str("TIBM") | str("TTB") | str("EAB") |
          str("JPCRD") | str("JRES") |
          # NEW - CHIPS Act, NWIRP, and Research Brief series
          str("CHIPS") | str("NWIRP") | str("RB")
        ).as(:series)
      end

      # Suffix letter(s) after number - supports single letters and specific two-letter suffixes
      # Two-letter suffixes: Ur (Unclassified Revised), Ua (Unclassified Amended), Ub-Uj (series variants)
      # Single letter: any letter not followed by excluded keywords
      rule(:number_suffix) do
        (str("U") >> lower_letter) | (match("[a-zA-Z]") >> (
          # Match suffixes
          str("ec") |
          str("ndex") |
          str("nsert") |
          str("rrata") |
          str("raft") | # NEW: Exclude "draft" from number suffix matching
          str("pp") |
          str("s") |
          str("t") |
          str("hi") |
          str("iet") |
          str("ort") |
          str("r") | # NEW: Exclude "r" revision marker (e.g., r5, r1963)
          str("p") # NEW: Exclude "p" part marker (e.g., 28p11969 - part with year pattern)
        ).absent? >>
          digits.maybe)
      end

      rule(:digits_with_suffix) do
        digits >>
          # Suffix only if not followed by digit (e.g., don't match 'e' in '140e2')
          (number_suffix >> digit.absent?).maybe
      end

      # Report number - first part - support edition prefixes like "e104" and supplement suffixes like "144supp"
      # Supplements should be handled as separate parts
      rule(:first_number) do
        (
          # OWMWP date format: MM-DD-YYYY (e.g., 06-13-2018)
          # Must be FIRST to match before other dash patterns
          (match("[0-9]").repeat(2, 2).as(:owmwp_month) >> dash >>
           match("[0-9]").repeat(2, 2).as(:owmwp_day) >> dash >>
           match("[0-9]").repeat(4, 4).as(:owmwp_year)).as(:owmwp_date_number) |
          # Special text patterns - MOST SPECIFIC FIRST (NEW for RPT patterns)
          str("ADHOC") | (str("div") >> digits) |
          # Month ranges for RPT: Apr-Jun1948 (NEW)
          (month_abbrev >> dash >> month_abbrev >> digits) |
          # Number with volume suffix (e.g., "539v10" for CIRC, "1011v1" for general patterns)
          # CRITICAL: Must be before CS series pattern to avoid consuming "GB" as letter suffix
          (digits.as(:number) >> str("v") >> digits.as(:volume_suffix)).as(:number_with_volume) |
          # Roman numeral patterns: 1011-I-2.0, 1011-II-1.0 (ENHANCED to accept optional dots)
          (digits >> dash >> (str("III") | str("II") | str("IV") | str("I") | str("V") | str("VI") | str("VII") | str("VIII") | str("IX") | str("X")) >> dash >> digits >> (dot >> digits).maybe) |
          # GB series pattern: 1190GB-1, 1190GB-4A
          (digits >> str("GB") >> dash >> digits >> upper_letter.maybe) |
          # CS series pattern with letter in middle: 102E-42, 123A-50
          (digits >> upper_letter >> dash >> digits) |
          # Volume-number format for CSM series: v6n1, v7n12
          # CHANGED: Capture volume and issue_number separately for proper semantics
          (str("v") >> digits.as(:volume_number) >> str("n") >> digits.as(:issue_number)) |
          # Regular number with supplement and revision suffix: "154supprev"
          (digits >> str("supprev")) |
          # Regular number with edition and revision year-only: "13e2rev1908"
          (digits >> str("e") >> digits >> str("rev") >> digits) |
          # NEW: Number with revision year (rv pattern for LetterCircular): "1013rv1953"
          (digits.as(:number) >> str("rv") >> digits.as(:revision_year)).as(:number_with_rev_year) |
          # Regular number with edition, revision, and month-date: "13e2revJune1908"
          (digits >> str("e") >> digits >> str("rev") >> month_abbrev >> digits) |
          # Regular number with eN suffix and optional supplement (e.g., "101e2supp") - most specific
          (digits >> str("e") >> digits >> str("supp") >> digits.maybe) |
          # Edition prefix with revision and date: e2revJune1908
          (str("e") >> digits >> str("rev") >> month_abbrev >> digits) |
          # Edition prefix followed by digits and optional supplement with digits
          (str("e") >> digits >> str("supp") >> digits.maybe) |
          # Regular number with eN suffix (e.g., "101e2")
          (digits >> str("e") >> digits) |
          # NEW: Bare edition (just "e2" without number prefix)
          (str("e") >> digits >> (dash >> digits).absent?) |
          # Letter prefix with digits (e.g., "c4" for CRPL)
          (lower_letter >> digits) |
          # Regular number with supplement suffix with month/year (e.g., "24suppJan1924")
          (digits >> str("supp") >> month_abbrev >> digits) |
          # Regular number with supplement suffix (e.g., "144supp") - with optional digits
          (digits >> str("supp") >> digits.maybe) |
          # Regular number with supplement suffix followed by month/year for date range
          (digits >> str("sup") >> month_abbrev >> digits) |
          # Regular number with "sup" suffix (e.g., "9350sup") - NEW for RPT patterns
          (digits >> str("sup")) |
          # Language code suffix without separator (e.g., "1088sp")
          # Must come BEFORE general suffix pattern to capture specific language codes
          # Must come AFTER other patterns (like sup, supp, etc.) to avoid consuming them
          # Note: Preprocessing doesn't convert attached suffixes, so we handle both cases
          (digits.as(:number) >> (str("sp") | str("pt") | str("es") | str("SP") | str("PT") | str("ES")).as(:language_code) >> (upper_letter.absent? >> digit.absent? >> letter.absent? >> dash.absent? >> dot.absent?)) |
          # Part+edition suffix for MR format: "28pt1e1969" (part notation + edition year)
          # Handles patterns like "NBS.HB.28pt1e1969" where part and edition are attached
          # Must come BEFORE language code pattern to take priority
          (digits.as(:number) >> str("pt") >> digits.as(:part_number) >> str("e") >> digits.as(:edition_year)) |
          # Parenthetical language code (e.g., "378(sp)")
          # Must come AFTER other patterns to avoid consuming letter suffixes
          # Note: Preprocessing converts content inside parentheses to uppercase
          # Use specific patterns to avoid consuming other parenthetical content
          (digits.as(:number) >> str("(") >> (str("SP") | str("PT") | str("ES")).as(:language_code) >> str(")")) |
          # Number with letter suffix followed by revision (e.g., "8278Ar1", "256Ar1930")
          # CRITICAL: Must come BEFORE digits_with_suffix because number_suffix's
          # str("r").absent? guard rejects any letter followed by 'r' (would
          # otherwise drop the letter and parse "256" + "Ar1930" as garbage).
          (digits.as(:number) >>
           upper_letter.as(:letter_suffix) >>
           str("r") >>
           digits.as(:revision_id)).as(:number_with_letter_revision) |
          # Regular number with optional suffix (original) - includes letters like "A"
          digits_with_suffix
        ).as(:first_number)
      end

      # Second number (after dash) - allow pt suffix, letter suffixes, and CRPL patterns
      rule(:second_number) do
        # Explicitly exclude month abbreviations at start (so -Feb1985 goes to edition, not second_number)
        month_abbrev.absent? >>
          # NEW: Exclude "draft" keyword
          str("draft").absent? >>
          (
            # Trailing bare supplement marker on a compound second number
            # (e.g. "800-53sup") so it isn't split into "53s" + "up". Builder
            # strips the marker and sets supplement="" (canonical "sup").
            (digits >> (str("supp") | str("sup")) >>
              (digit.absent? >> letter.absent?)) |
            # NEW: Revision pattern with U+letter suffix (e.g., "22r1Ua", "38Ua")
            # MUST come BEFORE general letter suffix to avoid matching just "U" from "Ua"
            (digits >> str("r") >> digits >> str("U") >> lower_letter) |
            # NEW: Revision pattern with letter suffix (e.g., "22r1a", "22r1A" for SP patterns)
            # This allows second_number to match the entire "22r1A" as a single unit
            # MUST come BEFORE plain r+digits to avoid greedy match of just "22r1"
            (digits >> str("r") >> digits >> match("[a-zA-Z]")) |
            # NEW: Revision pattern with year (e.g., "126r2013")
            # This handles SP revision format where revision is attached to second_number
            (digits.as(:number_only) >> str("r") >> digits.as(:edition_id)) |
            # CRPL range with underscore (e.g., "2_3-1A")
            (digits >> str("_") >> digits >> dash >> digits >> upper_letter.maybe) |
            # Letter followed by dash and digits (e.g., "m-5")
            (lower_letter >> dash >> digits) |
            # Number with pt suffix (e.g., "57pt1")
            # EXCLUDE pt#-# patterns (e.g., "pt3-1") which are part components for CRPL
            # Use negative lookahead to prevent matching when followed by dash
            (digits >> str("pt") >> digits >> dash.absent?) |
            # Number with uppercase letter suffix (e.g., "56A", "123B") - for patterns like "56Ar2"
            (digits >> upper_letter) |
            # NEW: Revision pattern where r is directly followed by a letter (e.g., "27ra" -> rA)
            # For patterns like NIST SP 800-27ra where revision 'ra' is attached directly to number
            (digits.as(:number_only) >> str("r") >> match("[a-zA-Z]").as(:letter)).as(:revision_letter) |
            # NEW: Revision pattern where r is directly followed by a letter without leading digits (e.g., "rA")
            # For patterns like NIST SP 800-27ra where revision 'ra' is attached directly to number
            (str("r") >> match("[a-zA-Z]")).as(:revision_letter_suffix) |
            # NEW: Simple revision pattern r followed by digits (e.g., "r1", "r2") for trailing revision
            (str("r") >> digits.as(:edition_id)).as(:revision_simple) |
            # Special patterns like "NCNR", "PERMIS", "BFRL"
            str("NCNR") | str("PERMIS") | str("BFRL") |
            # Just capital letters (e.g., "A", "B", "C") - standalone
            upper_letter.repeat(1, 3) |
            # Regular number with optional suffix - but NOT if part of FIPS date (digit-dash-month-digit-slash)
            (digits_with_suffix >> (dash >> month_abbrev >> digits >> slash).absent?) |
            # Single lowercase letter (e.g., "a", "b") - but NOT "r" followed by digits (edition marker)
            # This is for patterns like "126a" but not "126r2"
            (lower_letter >> digit.absent?)
          ).as(:second_number)
      end

      # Edition component per NIST spec: <edition-type><edition-id>
      # Type: "e" (edition), "r" (revision), "rev" (revision verbose), "-" (historical)
      # ID: number (1-9) or year (yyyy)
      # Examples: e2, e2021, r5, rev2013, rev 2013, -3
      # Enhanced: Support space-separated format from preprocessing (r1 separated from number)
      rule(:edition) do
        # Edition with "e" prefix: e2, e3, e2021 (1-4 digits for ID)
        (space.maybe >> str("e") >> digits.as(:edition_id)).as(:edition_e) |
          # Revision with "r" prefix and SPACE, with letter: r 5A (preserve format)
          (space >> str("r") >> digits.as(:edition_id) >> match("[a-zA-Z]").as(:edition_letter)).as(:edition_r_with_space_letter) |
          # Revision with "r" prefix and SPACE: r 5 (preserve format)
          (space >> str("r") >> digits.as(:edition_id)).as(:edition_r_with_space) |
          # Revision with "r" prefix NO space, with letter: r5A (compact format)
          (str("r") >> digits.as(:edition_id) >> match("[a-zA-Z]").as(:edition_letter)).as(:edition_r_no_space_letter) |
          # Revision with "r" prefix NO space: r5 (compact format)
          (str("r") >> digits.as(:edition_id)).as(:edition_r_no_space) |
          # Revision with "rev" prefix (verbose): rev2013, rev 2013
          (space.maybe >> str("rev") >> space.maybe >> digits.as(:edition_id)).as(:edition_rev) |
          # Historical with "-" prefix: -2, -3 (ONLY if followed by non-digit or end)
          # This avoids consuming date patterns like "-1908"
          # Historical precedent uses small numbers (1-9), dates use 4-digit years
          (dash >> match("[1-9]").as(:edition_id) >> digit.absent?).as(:edition_historical) |
          # Edition dash-year pattern: -1979, -1990 (dash + 4-digit year)
          # This matches year-only editions like "NBS HB 130-1979"
          (dash >> match("[0-9]").repeat(4,
                                         4).as(:dash_year)).as(:edition_dash_year)
      end

      # Date component per NIST spec: -{YYYY} or -{YYYYMM} or -{YYYYMMDD}
      # Separate from Edition - both can coexist
      # Examples: -1908, -190806, -19770930
      rule(:date) do
        (
          # Date with month and day: -19770930 (YYYYMMDD)
          (dash >> match("[0-9]").repeat(4, 4).as(:date_year) >>
           match("[0-9]").repeat(2, 2).as(:date_month) >>
           match("[0-9]").repeat(2, 2).as(:date_day)) |
          # Date with month: -190806 (YYYYMM)
          (dash >> match("[0-9]").repeat(4, 4).as(:date_year) >>
           match("[0-9]").repeat(2, 2).as(:date_month)) |
          # Date with year only: -1908 (YYYY)
          (dash >> match("[0-9]").repeat(4, 4).as(:date_year)) |
          # Legacy month format: -June1908, -Jan1925 (normalize to YYYYMM)
          (dash >> month_abbrev.as(:date_month) >> digits.as(:date_year))
        ).as(:date)
      end

      # ISO date token (YYYY-MM-DD) for date-style identifiers
      rule(:iso_date) do
        (match("[0-9]").repeat(4, 4).as(:date_year) >> dash >>
         match("[0-9]").repeat(2, 2).as(:date_month) >> dash >>
         match("[0-9]").repeat(2, 2).as(:date_day))
      end

      # Date-style identifier with no series (e.g. "NIST 2022-04-15 001",
      # "NIST.2022-04-15.001" — DOI 10.6028/NIST.2022-04-15.001)
      rule(:dated_identifier) do
        hash_prefix.maybe >>
          publisher >> (space | dot) >>
          iso_date.as(:dated_date) >> (space | dot) >>
          match("[0-9]").repeat(1).as(:dated_seq)
      end

      # "NIST Research Library (YYYY)" — one-off NIST publication that doesn't
      # fit the standard series+number shape (no report number, year in parens).
      # See pubid/pubid#151.
      rule(:research_library_identifier) do
        publisher >> space >>
          str("Research Library").as(:series) >>
          (space >> str("(") >>
            match("[0-9]").repeat(4, 4).as(:year) >> str(")")).maybe
      end

      # LEGACY EDITION PATTERNS (for backward compatibility during migration)
      # These will be gradually replaced as we migrate to proper Edition/Date components
      rule(:legacy_edition) do
        # Complex revision patterns: r1a, r2b
        ((str("r") | str(" R")) >> match("[0-9]").repeat(1,
                                                         2).as(:edition) >> lower_letter.as(:edition_letter)) |
          # Edition with revision and year: rev2013, rev2020, rev 2013 (with space)
          (str("rev") >> space.maybe >> digits.as(:edition_year)) |
          # Edition with revision and date: e2revJune1908 (will migrate to e2 + date)
          ((str("e") | str(" E")) >> match("[0-9]").repeat(1, 3).as(:edition) >>
           str("rev") >> match("[A-Za-z]").repeat(3,
                                                  9).as(:edition_month) >> digits.as(:edition_year)) |
          # Edition with year and month: e201801 (ambiguous - could be e2018 or year 2018 month 01)
          (str("e") >> match("[0-9]").repeat(4,
                                             4).as(:edition_year) >> match("[0-9]").repeat(
                                               2, 2
                                             ).as(:edition_month).maybe) |
          # Revision-based edition: revJune1908, revJan1925 (normalize to date)
          (str("rev") >> match("[A-Za-z]").repeat(3,
                                                  9).as(:edition_month) >> digits.as(:edition_year))
      end

      # CRPL range pattern (e.g., 1-2_3-1, 1-2_3-1A with suffix) - matches after first dash
      rule(:crpl_range) do
        (digits >> str("_") >> digits >> dash >> digits >> upper_letter.maybe).as(:crpl_range)
      end

      # Full report number - support dot-separated parts AND CRPL ranges
      # ENHANCED: Support multiple dashes for GCR patterns (Session 220)
      # FIXED: Put GCR pattern first to prioritize matching full dash-separated patterns
      # FIXED: Add edition.maybe to support revision patterns like 800-53r5 in short format
      # FIXED: Month abbreviation as edition (e.g., 107-Mar1985, 11-Jan1925)
      # FIXED: FIPS date format with day and slash (e.g., 11-1-Sep30/1977)
      rule(:report_number) do
        first_number >>
          (
            # Underscore edition-year (space-form mirror of mr_identifier): "1648_2009"
            (str("_") >> digits.as(:edition_year)) |
            # Month abbreviation as edition (e.g., 107-Mar1985, 11-Jan1925)
            # MUST BE FIRST to catch -MonthYear patterns before they're
            # incorrectly parsed as other alternatives
            (dash >> month_abbrev.as(:edition_month) >> digits.as(:edition_year)) |
            # FIPS date format: -1-Sep30/1977 (part-month-day/year with slash)
            # Must come before GCR pattern to avoid being matched as multi-dash
            (dash >> digits.as(:fips_part) >> dash >> month_abbrev.as(:edition_month) >>
             digits.as(:edition_day) >> slash >> digits.as(:edition_year)) |
            # Dash with decimal suffix (e.g., 80-2073.3, 123-45.67)
            # Must come before GCR pattern which expects another dash after second_number
            (dash >> digits.as(:decimal_base) >> dot >> digits.as(:decimal_suffix)).as(:decimal_number) |
            # Dash with letter suffix (e.g., 1-1A, 1-3B for NCSTAR, 73-197Ur for IR)
            # Must come before GCR pattern which expects another dash
            # Supports U+lowercase letter suffix (e.g., Ur, Ua, Ub-Uj for Unclassified variants)
            # For other uppercase letters, only match single letter (A, B, C) to avoid consuming revision r
            (dash >> digits.as(:letter_base) >> (
              (str("U") >> lower_letter.as(:letter_suffix_extra)) |
              upper_letter
            ).as(:letter_suffix)).as(:letter_number) |
            # Dash-SEPARATED letter suffix on a numbered part (e.g., 21-4-B,
            # 173-1-B for FIPS, and the reparseable form of letter_number's own
            # rendered output 200-30-B). The month_abbrev guard keeps FIPS date
            # forms like 11-1-Sep1977 with the earlier patterns; the trailing
            # guard restricts to a single clean letter so GCR -200-30B is unaffected.
            (dash >> digits.as(:letter_base) >> dash >> month_abbrev.absent? >>
             upper_letter.as(:letter_suffix) >> (letter | digit).absent?).as(:letter_number) |
            # Edition dash-year pattern (e.g., -1979 for handbooks like "NBS HB 130-1979")
            # Matches any 4-digit sequence - the builder decides if it's a year or second_number
            (dash >> match("[0-9]").repeat(4,
                                           4).as(:dash_year) >> (space | dot | part | crpl_range | second_number | dash).absent?).as(:edition_dash_year) |
            # Second number followed by edition dash-year (e.g., -1-1990 for "105-1-1990")
            # Handles compound numbers with edition year at the end
            # MUST be BEFORE GCR pattern because both start with dash + second_number + dash
            (dash >> second_number >> dash >> match("[0-9]").repeat(4,
                                                                    4).as(:dash_year) >> (space | dot | part | crpl_range | revision | draft).absent?).as(:second_number_edition_year) |
            # FIPS month+year pattern after part (e.g., -1-Sep1977 for "11-1-Sep1977")
            (dash >> second_number >> dash >> month_abbrev.as(:edition_month) >> digits.as(:edition_year) >> (space | dot | part | crpl_range | edition | revision | draft).absent?).as(:fips_month_year_after_part) |
            # GCR multi-dash pattern (e.g., 85-3273-37, 19-200-30B)
            (dash >> second_number >> dash >> (digits >> upper_letter.maybe).as(:part_number)) |
            # Dot-separated part (e.g., 984.4 = number 984, part 4)
            (dot >> second_number) |
            # Dash-separated with optional revision (e.g., 800-53r5, 1019r1963)
            (dash >> (crpl_range | second_number) >> edition.maybe) |
            (dash >> edition)
            # TODO: Language code suffix without separator (e.g., "1088sp")
            # Must come AFTER other patterns to avoid consuming them
            # | (str("sp") | str("pt") | str("es") | match("[a-z]").repeat(2, 4)).as(:language_code) >> (space | dot | part | crpl_range | second_number).absent?) |
            # Parenthetical language code (e.g., "378(sp)")
            # | (str("(") >> match("[a-z]").repeat(2, 4).as(:language_code) >> str(")") >> (space | dot | part | crpl_range | second_number).absent?)
          ).maybe
      end

      # Volume
      rule(:volume) do
        # Long-form "Vol." comes FIRST so PEG ordered choice doesn't commit to
        # the bare "v" alternative after consuming the leading space via
        # space.maybe (which would then starve the " Vol. " form). Both
        # "Vol. 4" (period + space) and "Vol.4" (period only) are accepted.
        (space.maybe >>
          (str("Vol. ") | str("Vol.") | str("v"))) >>
          (digits >>
           # Support letter ranges (lowercase normalized in preprocessing)
           (str("a-l") | str("m-z") | str("A-L") | str("M-Z")).maybe >>
           # Support single uppercase letters (e.g., v3B, v1A)
           upper_letter.repeat(0, 2)).as(:volume)
      end

      # Part - enhanced to support patterns like p1adde1 AND pt3r1 (part with revision)
      rule(:part) do
        (str(" Part. ") | str(" Part.") | str(" Part ") |
         (space.maybe >> (str("pt") | str("p") | str("P")))) >>
          (digits >>
           # NEW: Revision after part number: pt3r1, p1r1 (space.maybe for preprocessing)
           (space.maybe >> str("r") >> digits).maybe >>
           # Existing: Addendum with optional edition: add, adde1
           (str("add") >> (str("e") >> digits).maybe).maybe >>
           (dash >> digits).maybe).as(:part)
      end

      # Revision
      rule(:revision) do
        # NEW: Revision with month and year: rJun1992, r Jun1992 - LONGEST MATCH FIRST
        # Enhanced to support leading space (Session 219)
        (space.maybe >> (str("r") | str("rev")) >> space.maybe >> month_abbrev.as(:revision_month) >> digits.as(:revision_year)) |
          # Revision with slash and year: r6/1925, r11/1924 (NEW for LCIRC patterns)
          (space.maybe >> (str("r") | str("rev")) >> digits.as(:revision) >>
           slash >> digits.as(:revision_year)) |
          # Revision with 4-digit year directly: r1995, r 1995 (allow space before year)
          ((str(" r") | str("r")) >> space.maybe >> match("[0-9]").repeat(4,
                                                                          4).as(:revision_year)) |
          # Revision with year: rev2013, rev 2013 (allow space before year)
          (str("rev") >> space.maybe >> digits.as(:revision_year)) |
          # Revision with digits AND/OR letters: r1a, r1A, ra, r1
          # Enhanced to accept letter-only revisions and space before r
          # ENHANCED: Accept BOTH lowercase and uppercase letters in suffix
          # ENHANCED: Capture original format prefix for format preservation (e.g., " Rev. 5")
          ((str(" rev ") | str("rev") | str(" r") | str("r") | str(" Rev. ") | str(" Rev.") | str(" Revision (r)")).as(:revision_prefix) >>
           space.maybe >>
            ((digits >> match("[a-zA-Z]").maybe) | match("[a-zA-Z]").repeat(1)).as(:revision_id)).as(:revision) |
          # NEW: Standalone 'r' - MUST BE LAST to avoid consuming from other patterns
          # Matches " r" at end of input (after preprocessing: "800-56a r", "800-27 r")
          (str(" r") >> any.absent?).as(:revision_standalone)
      end

      # Version - V1 SP PARSER COMPATIBLE
      # Supports: ver1.0.2, ver2, " Ver. 2.0", " Version 1.0", v1.0.2, -v1.0, .ver1.0 (MR format)
      rule(:version) do
        # Verbose "ver" form - with or without dots (space.maybe before AND after "ver")
        # ENHANCED: Accept dot prefix for MR format (e.g., "500-281.ver1.0")
        ((space | dot).maybe >> str("ver") >> space.maybe >> (digits >> (dot >> digits).repeat).as(:version)) |
          # Verbose forms with space: " Ver. ", " Version " - require dots
          ((str(" Ver. ") | str(" Version ")) >>
            (digits >> dot >> digits >> (dot >> digits).maybe).as(:version)) |
          # Short form "v" with mandatory dots (v1.0, v1.0.2) - allow optional dash or space before
          ((dash | space).maybe >> str("v") >> (digits >> dot >> digits >> (dot >> digits).maybe).as(:version))
      end

      # Update - V1 COMPATIBLE
      # Format: /Upd{N}-{YYYY}{MM} where MM is optional
      # Examples: /Upd1-2015, /Upd3-202102, -upd, /upd (after preprocessing)
      # Update number is optional (e.g., "500-300-upd" has no number)
      # Captures prefix to preserve original format (-upd vs /Upd)
      rule(:update) do
        prefix = (
          str("/Upd") |
          (space.maybe >> (str("/upd") | str("-upd")))
        ).as(:update_prefix)

        prefix >>
          (
            digits.as(:update_number).maybe >>
            (dash >>
              (
                # Real updates: 4-digit year + optional 2-digit month
                # (e.g. /Upd1-2015, /Upd3-202102).
                (match("[0-9]").repeat(4, 4).as(:update_year) >>
                 match("[0-9]").repeat(2, 2).as(:update_month)) |
                # Fallback: capture the whole digit run as the year. Handles the
                # unpadded CIRC/LCIRC supplement form pubid emits, where year and
                # revision are fused without a 2-digit month boundary
                # (e.g. /Upd1-19256 = 1925 + revision 6). Keeps these strings
                # re-parseable so generated ids round-trip.
                match("[0-9]").repeat(4).as(:update_year)
              )
            ).maybe
          ).as(:update)
      end

      # Addendum
      rule(:addendum) do
        ((str("-add") | str(".add") | str(" Add.")) >>
          (space | dash).maybe >> (digits | str("")).as(:addendum_number)).as(:addendum)
      end

      # Supplement - enhanced to support date patterns, year patterns, and combined with revision
      # Examples: suppJan1924, supp3/1926, supp1925, supJun1925-Jun1927 (date ranges), supprev
      rule(:supplement) do
        space.maybe >>
          (str("supp") | str("sup")) >>
          (
            # Supplement followed by revision: supprev
            str("rev").as(:supplement_with_rev) |
            # Date range pattern: Jan1924-Jan1926
            (month_abbrev.as(:supp_month_start) >> digits.as(:supp_year_start) >>
             dash >> month_abbrev.as(:supp_month_end) >> digits.as(:supp_year_end)).as(:supplement_date_range) |
            # Month and year: Jan1924
            (month_abbrev.as(:supp_month) >> digits.as(:supp_year)).as(:supplement_date) |
            # Number with slash and year: 3/1926
            (digits.as(:supp_number) >> slash >> digits.as(:supp_year)).as(:supplement_slash_year) |
            # Just year: 1925
            digits.as(:supp_year) |
            # General suffix (other patterns)
            match("[A-Za-z0-9]").repeat(1).as(:supplement_suffix)
          ).maybe
      end

      # Errata
      rule(:errata) do
        (dash.maybe >> (str("errata") | str("err"))).as(:errata)
      end

      # Index
      rule(:index) do
        (str("index") | str("indx")).as(:index)
      end

      # Insert
      rule(:insert) do
        (str("insert") | str("ins")).as(:insert)
      end

      # Appendix
      rule(:appendix) do
        str("app").as(:appendix)
      end

      # Section - make digits optional for patterns like just "sec"
      rule(:section) do
        str("sec") >> digits.as(:section).maybe
      end

      # Translation (3-letter language code) - V1 COMPATIBLE
      # Supports: (spa), " spa", ".spa" (MR format)
      rule(:translation) do
        # Parenthetical format: (spa), (por), (ind)
        (str("(") >> match('\w').repeat(3, 3).as(:translation) >> str(")")) |
          # Space-prefix format: " spa"
          (space >> match('\w').repeat(3, 3).as(:translation)) |
          # Dot-prefix format: ".spa" (machine-readable), optional leading space: " .spa"
          (space.maybe >> dot >> match('\w').repeat(3, 3).as(:translation))
      end

      # Public draft suffix - for patterns like 2pd, 3pd
      rule(:pd_suffix) do
        (space >> digits >> str("pd")).as(:public_draft)
      end

      # Draft stage - enhanced to support suffix pattern and number after draft
      # ENHANCED: Accept optional space before dash to match after report_number
      rule(:draft) do
        ((space >> str("(Draft)")) |
         (space.maybe >> dash >> str("draft") >> ((space >> digits) | digits).maybe) | # Match " -draft 2" OR "-draft2"
         pd_suffix).as(:draft)
      end

      # Special date format with slash for FIPS (part of number, not edition)
      rule(:fips_date) do
        dash >> digits.as(:fips_part) >> dash >> month_abbrev.as(:fips_month) >>
          digits.as(:fips_day) >> slash >> digits.as(:fips_year)
      end

      # All possible parts (order matters!)
      rule(:parts) do
        # Put more specific patterns first
        # CRITICAL: new_stage BEFORE language_code to avoid "ipd" being treated as translation
        new_stage |
          section | index | insert | appendix | pd_suffix |
          edition | date | legacy_edition | revision |
          version | # MOVED BEFORE volume - try dotted versions (v1.1) before simple volumes (v1)
          volume | part | update | addendum |
          supplement | errata | language_code
      end

      # CIRC Supplement identifier - split into base + supplement
      # Examples:
      # - "NBS CIRC 101e2supp" → base="NBS CIRC 101e2", supplement
      # - "NBS CIRC 25supp-1924" → base="NBS CIRC 25", supplement_year="1924"
      # - "NBS CIRC 24suppJan1924" → base="NBS CIRC 24", supplement_edition="Jan1924"
      # - "NBS CIRC suppJun1925-Jun1926" → date range supplement (no base)
      # - "NBS LCIRC 378Gsup" → base="NBS LCIRC 378G", supplement (no metadata)
      # - "NBS.LCIRC.378sup1/1927" → dot-separated MR format (after preprocessing)
      # Dot-separated machine-readable format: NIST.SP.800-116 or #NIST.2024-01-15.123
      # Enhanced to support parts after number like NIST.SP.1011-I-2.0
      # Enhanced to support revision+update patterns like NIST.IR.8115r1-upd
      rule(:mr_identifier) do
        hash_prefix.maybe >>
          publisher >> dot >>
          simple_series >> dot >>
          report_number >>
          # Edition with underscore separator (MR format: 1648_2009)
          (str("_") >> digits.as(:edition_year)).maybe >>
          # Support letter suffix before update (e.g., 8286C-upd1) - Session 219
          upper_letter.maybe >>
          # Support revision component (r1, r5, etc.) before update
          edition.maybe >>
          update.maybe >>
          # Additional dot-separated parts (parts, version, volume, etc.)
          # MUST come before translation to avoid conflicting with language codes
          (dot >> (digits | upper_letter)).repeat(0, 3) >>
          # Language codes at end (.spa, .por, .ind)
          parts.repeat >> draft.maybe
      end

      # Main identifier structure
      # Try compound series first (longest match), then publisher + simple series
      rule(:identifier) do
        circ_supplement_identifier |
          dated_identifier |
          mr_identifier |
          research_library_identifier |
          (
            # Compound series (includes publisher in series name)
            compound_series >> (space | dot) >>
            old_stage.maybe >> # Old style stage after series
            report_number.maybe >> fips_date.maybe >> parts.repeat >> draft.maybe >> translation.maybe >> new_stage.maybe
          ) |
          (
            # Publisher + simple series - require space/dot between publisher and series
            publisher >> (space | dot) >>
            simple_series >>
            old_stage.maybe >> # Old style stage after series
            (space | dot) >>
            report_number.maybe >> fips_date.maybe >> parts.repeat >> draft.maybe >> translation.maybe >> new_stage.maybe
          ) |
          (
            # Simple series only (no publisher)
            simple_series >>
            old_stage.maybe >> # Old style stage after series
            (space | dot) >>
            report_number.maybe >> fips_date.maybe >> parts.repeat >> draft.maybe >> translation.maybe >> new_stage.maybe
          )
      end

      # CIRC Supplement identifier - split into base + supplement
      # Must be complete rule with all patterns
      rule(:circ_supplement_identifier) do
        (
          (str("NBS CIRC") | str("NBS LCIRC") | str("NBS.CIRC") | str("NBS.LCIRC")).as(:series) >>
          (space | dot)
        ).as(:circ_series) >>
          (
            # Date range supplement (no base number)
            (str("supp") >> month_abbrev.as(:supp_month_start) >> digits.as(:supp_year_start) >>
             dash >> month_abbrev.as(:supp_month_end) >> digits.as(:supp_year_end)).as(:supplement_date_range) |
            # Year-only date range supplement to the whole series, no months
            # (e.g. "NBS CIRC sup1925-1926" — pubid/pubid#152). Requires two
            # 4-digit years so it can't swallow "sup3/1926" or a base number.
            ((str("supp") | str("sup")) >> match("[0-9]").repeat(4, 4).as(:supp_year_start) >>
             dash >> match("[0-9]").repeat(4, 4).as(:supp_year_end)).as(:supplement_date_range) |
            # With base identifier + supplement
            (
              # Capture base portion (everything before "supp" or "sup" or slash+year)
              (
                # Number with edition: "101e2"
                (digits.as(:base_number) >> str("e") >> digits.as(:edition_number)) |
                # Number with revision (for supplement patterns): "145r11"
                (digits.as(:base_number) >> lower_letter.as(:revision_letter) >> digits.as(:revision_number)) |
                # Number with letter suffix: "378G"
                (digits.as(:base_number) >> upper_letter.as(:letter_suffix)) |
                # Just number: "25", "24"
                digits.as(:simple_number)
              ).as(:base_portion) >>
              # Supplement marker - support both "supp" and "sup", OR implicit supplement via slash+year
              (
                # Explicit supplement marker
                ((str("supp") | str("sup")) >>
                # Optional supplement metadata
                (
                  (month_abbrev >> digits).as(:supplement_month_year) |
                  # Dash + number + slash + year (e.g., supp-12/1926)
                  (dash >> digits.as(:supp_number) >> slash >> digits.as(:supp_year)).as(:supplement_dash_slash_year) |
                  (dash >> digits.as(:supplement_year)) |
                  (digits.as(:supp_number) >> slash >> digits.as(:supp_year)).as(:supplement_slash_year) |
                  str("").as(:supplement_empty)
                ).maybe) |
                # Implicit supplement via slash+year (e.g., "145r11/1925")
                (slash >> digits.as(:implicit_supplement_year)).as(:implicit_supplement)
              )
            )
          )
      end

      root(:identifier)
    end
  end
end
