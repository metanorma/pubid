# frozen_string_literal: true

require "parslet"

module Pubid
  module Astm
    class Parser < Parslet::Parser
      # Basic building blocks
      rule(:space) { str(" ") }
      rule(:dash) { str("-") }
      rule(:slash) { str("/") }
      rule(:colon) { str(":") }
      rule(:dot) { str(".") }
      rule(:digit) { match("[0-9]") }
      rule(:digits) { digit.repeat(1) }
      rule(:letter) { match("[A-Z]") }
      rule(:letters) { letter.repeat(1) }

      # Publisher
      rule(:publisher) { str("ASTM").as(:publisher) >> space.maybe }

      # Letters A-G for standard types
      rule(:standard_letter) { match("[A-G]").as(:letter) }

      # Year patterns (2-digit)
      rule(:year_2digit) { digit.repeat(2, 2).as(:year) }

      # Reapproval notation (may have comment after)
      rule(:reapproval) do
        str("(") >> digit.repeat(4, 4).as(:reapproval) >> str(")")
      end

      # Comment portion (anything after #)
      rule(:comment) { space.maybe >> str("#") >> match("[^#]").repeat }

      # Edition notations - supports both ordinal (1ST, 2ND) and e-notation (e1, e2)
      # For e-notation, capture just the digits (not the 'e' prefix)
      # For ordinal notation, capture the whole string
      rule(:edition) do
        (
          (str("e") >> digits.as(:edition_number)) |
          str("9TH") | str("8TH") | str("7TH") | str("6TH") |
          str("5TH") | str("4TH") | str("3RD") | str("2ND") |
          str("1ST")
        ).as(:edition)
      end

      # Sub-year notation (a, b, c)
      rule(:sub_year) { match("[a-c]").as(:sub_year) }

      # Format suffix
      rule(:format_suffix) { dash >> str("EB").as(:format_suffix) }

      # Format suffix without dash (for use after supplement which ends with dash)
      rule(:format_suffix_no_dash) { str("EB").as(:format_suffix) }

      # Supplement notation (ends with dash)
      rule(:supplement) { dash >> str("SUP").as(:supplement) >> dash }

      # ========================================
      # Research Report - MOST SPECIFIC (has colon)
      # ========================================
      rule(:research_report) do
        publisher.maybe >>
          str("RR").as(:type) >>
          colon >>
          (letter >> digit.repeat(2, 2)).as(:committee) >>
          dash >>
          digits.as(:number)
      end

      # ========================================
      # Manual
      # ========================================
      rule(:manual) do
        publisher.maybe >>
          str("MNL").as(:type) >>
          str("TP").as(:tp_designation).maybe >>
          digits.as(:number) >>
          (dash >> edition).maybe >>
          (
            (supplement >> format_suffix_no_dash.maybe) |
            format_suffix.maybe
          )
      end

      # ========================================
      # Monograph
      # ========================================
      rule(:monograph) do
        publisher.maybe >>
          str("MONO").as(:type) >>
          digits.as(:number) >>
          (dash >> edition).maybe >>
          format_suffix.maybe
      end

      # ========================================
      # Data Series
      # ========================================
      rule(:data_series_suffix) { match("[A-Z]").as(:suffix) }
      # Subseries can be: -S4 OR S4 (when following a letter suffix)
      rule(:data_series_subseries_with_dash) do
        dash >> str("S") >> digits.as(:subseries)
      end
      rule(:data_series_subseries_no_dash) do
        digits.as(:subseries) # Directly after letter suffix
      end
      rule(:data_series_code) do
        digits.as(:number) >>
          (
            str("HOL").as(:hol_suffix) |
            (data_series_suffix >> (data_series_subseries_no_dash | data_series_subseries_with_dash).maybe) |
            data_series_subseries_with_dash
          ).maybe
      end

      rule(:data_series) do
        publisher.maybe >>
          str("DS").as(:type) >>
          data_series_code >>
          format_suffix.maybe
      end

      # ========================================
      # Work in Progress
      # ========================================
      rule(:work_in_progress) do
        publisher.maybe >>
          str("WK").as(:type) >>
          digits.as(:number)
      end

      # ========================================
      # Adjunct
      # ========================================
      # SEMANTIC NOTE: Adjunct identifiers reference a base standard
      # Structure: ADJ + base_standard_code + adjunct_designation
      # Examples:
      #   ADJF3504-EA: Adjunct to F3504, EA = Excel file format
      #   ADJC033501: Adjunct "01" to C335
      #   ADJC0450A: Adjunct format "A" to C450
      #   ADJE11211T: Adjunct "11T" to E112
      #   ADJDQCALC: Adjunct with text designation (not to numbered standard)
      # Adjunct formats: EA (Excel), E-PDF, A1A2 (arbitrary identifiers)
      # One standard can have multiple adjuncts
      rule(:adjunct) do
        publisher.maybe >>
          str("ADJ").as(:type) >>
          ((letter >> digits) | letters | digits).as(:designation) >>
          (dash >> str("EA")).maybe.as(:ea_suffix) >>
          str("DVD").maybe.as(:dvd_suffix)
      end

      # ========================================
      # Technical Report
      # ========================================
      rule(:technical_report_iso_astm) do
        str("ISO/ASTMTR").as(:type) >>
          digits.as(:number) >>
          format_suffix.maybe >>
          comment.maybe
      end

      rule(:technical_report_simple) do
        publisher.maybe >>
          str("TR").as(:type) >>
          digits.as(:number) >>
          format_suffix.maybe >>
          comment.maybe
      end

      rule(:technical_report) do
        technical_report_iso_astm | technical_report_simple
      end

      # ========================================
      # Standard (DEFAULT - handles A-G prefix AND digit-only E-standards)
      # ========================================

      # SEMANTIC NOTE: 5xxxx digit-only standards are ISO/ASTM dual-published
      # Examples:
      #   ASTM 52303-24e1: ASTM's version (e1 = edition 1, not "E" prefix)
      #   ISO/ASTM 52303:2024: ISO's published version of the same document
      # These should semantically be IsoDualPublishedIdentifier or similar
      # Parser currently accepts them as digit-only standards

      # NOTE: Reference Radiographs (RR) are a separate document type not yet implemented
      # Examples:
      #   RRE341903: Reference radiograph for standard E3419
      #   RRE015501: Reference radiograph, volume 1
      #   RRE2669CS: Adjunct to E2669 reference radiograph
      # These require separate ReferenceRadiograph identifier class

      # Dual unit pattern: F1862/F1862M
      rule(:dual_unit) do
        slash >>
          standard_letter >>
          digits >>
          str("M").as(:dual_m)
      end

      rule(:standard_code_with_letter) do
        standard_letter >>
          digits.as(:number) >>
          dual_unit.maybe
      end

      # Digit-only standards (primarily 5xxxx ISO/ASTM dual-published)
      # Parsed as digit-only, semantic meaning is dual-published with ISO
      rule(:standard_code_digit_only) do
        digits.as(:number) # Accept digit-only, no implicit E prefix
      end

      rule(:standard) do
        publisher.maybe >>
          (standard_code_with_letter | standard_code_digit_only) >>
          (
            dash >> year_2digit >>
            sub_year.maybe >>
            reapproval.maybe >>
            edition.maybe
          ).maybe >>
          comment.maybe
      end

      # ========================================
      # Main identifier rule - ORDER MATTERS!
      # ========================================
      rule(:identifier) do
        research_report | # Most specific (has colon)
          technical_report |      # Has TR prefix
          manual |                # Has MNL prefix
          monograph |             # Has MONO prefix
          data_series |           # Has DS prefix
          work_in_progress |      # Has WK prefix
          adjunct |               # Has ADJ prefix
          standard                # DEFAULT (A-G letter)
      end

      root(:identifier)
    end
  end
end
