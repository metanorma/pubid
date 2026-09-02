# frozen_string_literal: true

require "parslet"

module Pubid
  module Ashrae
    # Parser class for ASHRAE identifiers
    # Single Responsibility: Parsing ASHRAE identifier syntax
    class Parser < Parslet::Parser
      # Basic building blocks
      rule(:space) { str(" ") }
      rule(:space?) { space.maybe }
      rule(:dash) { str("-") }
      rule(:dot) { str(".") }
      rule(:slash) { str("/") }
      rule(:lparen) { str("(") }
      rule(:rparen) { str(")") }
      rule(:comma) { str(",") }
      rule(:colon) { str(":") }

      rule(:digit) { match("[0-9]") }
      rule(:digits) { digit.repeat(1) }
      rule(:letter) { match("[A-Za-z]") }

      # Year pattern (4 digits starting with 19 or 20)
      rule(:year_digits) do
        (str("19") | str("20")) >> digit.repeat(2, 2)
      end

      # Reaffirmation year (2 or 4 digits)
      rule(:reaffirmation_year) do
        year_digits | digit.repeat(2, 2)
      end

      # Publisher
      rule(:publisher) { str("ASHRAE") }

      # Type (Guideline or Standard)
      rule(:type) do
        str("Guideline") | str("Standard")
      end

      # Code pattern (e.g., 15, 90.1, 41.10, 118.1, 90A,B,C)
      rule(:code) do
        (
          digits >> # First part (e.g., 15, 90)
          (dot >> digits).repeat(0, 2) >> # Optional dotted parts (e.g., .1, .10)
          # Special pattern for codes like "90A,B,C" (letter + comma-separated letters)
          (
            letter >> # Single letter after digits (e.g., "A" in "90A")
            (comma >> letter).repeat(0, 10) # Optional comma-separated letters (e.g., ",B,C")
          ).maybe # This entire letter+commas pattern is optional
        ).as(:code)
      end

      # Code with year pattern (e.g., 34-2024, 62.1-2022, 90A-2010) - used when type is missing
      rule(:code_with_year) do
        (
          (
            digits >> # First part (e.g., 34, 62)
            (dot >> digits).repeat(0, 2) >> # Optional dotted parts (e.g., .1)
            # Special pattern for codes like "90A,B,C-2010"
            (
              letter >> # Single letter after digits
              (comma >> letter).repeat(0, 10) # Optional comma-separated letters
            ).maybe
          ).as(:code) >>
          space?.maybe >> dash >>
          year_digits.as(:year)
        ).as(:code_with_year)
      end

      # Suffix (R for revision, P for proposed)
      rule(:suffix) do
        (str("R") | str("P")).as(:suffix)
      end

      # Additional copublisher pattern (e.g., /AMCA 210-99 or (ANSI/AMCA 330-97))
      rule(:additional_copublisher) do
        (slash >> (letter.repeat(4,
                                 10) >> space >> (digits >> (dash >> digits).maybe).maybe).as(:additional_copublisher)) |
          (lparen >> (str("ANSI") >> slash >> (letter.repeat(2,
                                                             10) >> (slash >> letter.repeat(2, 10)).repeat(0,
                                                                                                           2))).as(:additional_copublisher) >> space >> (digits >> (dash >> digits).maybe).maybe >> rparen)
      end

      # Optional suffix in parentheses (PDF), (I-P and SI versions), long descriptions, etc.
      rule(:optional_suffix) do
        space.maybe >> lparen >> (
          str("PDF") | # Special case for PDF
          (letter.repeat(1, 20) >> (space | digit | comma | dash | dot | letter | str("–")).repeat(0, 500)) # General case including long descriptions
        ) >> rparen
      end

      # Reaffirmation pattern (RA YEAR or RA-YEAR)
      rule(:reaffirmed) do
        (space.maybe >> lparen >> str("RA") >> space? >> reaffirmation_year.as(:reaffirmed) >> rparen) |
          (space.maybe >> lparen >> str("RA") >> dash >> reaffirmation_year.as(:reaffirmed) >> rparen) |
          (space >> str("RA") >> space >> reaffirmation_year.as(:reaffirmed)) |
          (space >> str("RA") >> dash >> reaffirmation_year.as(:reaffirmed))
      end

      # Addendum code (single letter, multi-letter, or numeric-prefixed like 62o)
      rule(:addendum_code) do
        (digits.maybe >> letter.repeat(1, 3)).as(:addendum_code)
      end

      # Addendum date pattern (Month Day, Year - e.g., "January 22, 2019")
      rule(:month_name) do
        str("January") | str("February") | str("March") | str("April") | str("May") |
          str("June") | str("July") | str("August") | str("September") | str("October") |
          str("November") | str("December")
      end

      rule(:errata_date) do
        # Full date: (Month Day, Year)
        (lparen >> month_name >> space >> digit.repeat(1,
                                                       2) >> comma.maybe >> (space | comma.maybe) >>
         year_digits.as(:errata_year) >> rparen).as(:errata_date) |
          # Month+day without year: (August 27)
          (lparen >> month_name >> space >> digit.repeat(1,
                                                         2) >> rparen).as(:errata_date) |
          # Numeric date with dash: (7-17- 2003) or (7-17-2003)
          (lparen >> digit.repeat(1, 2) >> dash >> digit.repeat(1,
                                                                2) >> dash >> space.maybe >> year_digits.as(:errata_year) >> rparen).as(:errata_date)
      end

      # Errata suffix pattern - handles descriptive text like "– Spanish Edition" after "Errata"
      rule(:errata_suffix) do
        # Regular dash or em dash
        (space >> (str("-") | str("–")) >> space >> (letter >> (space | letter | digit | comma).repeat(0, 50))).repeat(
          0, 3
        )
      end

      # Errata suffix on addendum (e.g., "ASHRAE Addendum a to Standard 15-2001 Errata (July 6, 2021)")
      rule(:errata_suffix_on_addendum) do
        space >> str("Errata").as(:errata_keyword) >>
          (
            # Full date: (Month Day, Year)
            (space >> lparen >> month_name >> space >> digit.repeat(1,
                                                                    2) >> comma.maybe >> (space | comma.maybe) >> year_digits >> rparen) |
            # Month+day without year: (August 27)
            (space >> lparen >> month_name >> space >> digit.repeat(1,
                                                                    2) >> rparen) |
            # Numeric date with dash: (7-17-2003)
            (space >> lparen >> digit.repeat(1,
                                             2) >> dash >> digit.repeat(1,
                                                                        2) >> dash >> space.maybe >> year_digits >> rparen) |
            # No date at all
            str("")
          )
      end

      # Errata pattern (base identifier + " Errata (date)")
      rule(:errata_identifier) do
        # Format with copublisher: ANSI/ASHRAE Standard 105-2014 Errata (May 23, 2014)
        ((
          (
            (str("ANSI") >> dash >> str("ASHRAE")) |
            (str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
              0, 10
            ))
          ).as(:copublisher) >> space >>
          type.as(:type) >> space >>
          code >>
          (space?.maybe >> dash >> year_digits.as(:year)).maybe >>
          (space >> additional_copublisher).maybe >>
          suffix.maybe >>
          reaffirmed.maybe
        ).as(:base) >>
          space >>
          str("Errata").as(:errata_keyword) >>
          (
            (errata_suffix >> errata_date) |
            (errata_date >> errata_suffix) |
            errata_date |
            errata_suffix
          ).maybe >>
          optional_suffix.repeat(0, 2).as(:optional_suffixes)) |
          # Format with copublisher, missing type: ANSI/ASHRAE 51-1999 Errata (May 23, 2014)
          ((
            (
              (str("ANSI") >> dash >> str("ASHRAE")) |
              (str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
                0, 10
              ))
            ).as(:copublisher) >> space >>
            code_with_year >>
            (space >> additional_copublisher).maybe >>
            suffix.maybe >>
            reaffirmed.maybe
          ).as(:base) >>
            space >>
            str("Errata").as(:errata_keyword) >>
            (
              (errata_suffix >> errata_date) |
              (errata_date >> errata_suffix) |
              errata_date |
              errata_suffix
            ).maybe >>
            optional_suffix.repeat(0, 2).as(:optional_suffixes)) |
          # Format with publisher: ASHRAE Guideline 0-2005 Errata (September 28, 2011)
          ((
            publisher.as(:publisher) >> space >>
            type.as(:type) >> space >>
            code >>
            (space?.maybe >> dash >> year_digits.as(:year)).maybe >>
            (space >> additional_copublisher).maybe >>
            suffix.maybe >>
            reaffirmed.maybe
          ).as(:base) >>
            space >>
            str("Errata").as(:errata_keyword) >>
            errata_date.maybe >>
            errata_suffix.maybe >>
            optional_suffix.repeat(0, 2).as(:optional_suffixes))
      end

      # Interpretation pattern ("Interpretations for Standard X-YYYY")
      rule(:interpretation_identifier) do
        str("Interpretations") >> space >>
          str("for") >> space >>
          (type.as(:type) >> space >> code >> (dash >> year_digits.as(:year)).maybe).as(:base)
      end

      # Combined Addenda pattern (multiple addendums grouped together)
      rule(:combined_addenda_identifier) do
        # Format 1: ASHRAE Addenda X, Y and Z to Standard/Guideline X-YYYY
        (
          publisher.as(:publisher) >> space >>
          str("Addenda") >> space >>
          addendum_code >> # First addendum code
          (
            (comma >> space >> str("and") >> space >> addendum_code) | # ", and b"
            (space >> str("and") >> space >> addendum_code) |  # "and b"
            (comma >> space >> addendum_code).repeat(1, 10) |  # comma-separated: "a, b, c"
            (comma >> addendum_code).repeat(1, 10) # comma without space: "a,b,c"
          ).repeat(0, 3).as(:additional_codes) >> # Multiple groups of codes (0-3 to allow single code)
          space >>
          (str("to") | str("for")) >> space >>
          ((str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
            0, 10
          )).as(:copublisher) >> space).maybe >>
          type.as(:type) >> space >>
          code >>
          (dash >> year_digits.as(:year)).maybe >>
          (space >> additional_copublisher).maybe >>
          addendum_date_suffix.maybe >>
          optional_suffix.repeat(0, 2)
        ).as(:combined_addenda) |
          # Format 2: ASHRAE Standard X-YYYY: Addenda a, b, c (colon separator)
          (
            publisher.as(:publisher) >> space >>
            type.as(:type) >> space >>
            code >>
            (dash >> year_digits.as(:year)) >>
            ((colon >> space) | space) >>
            str("Addenda") >> space >>
            addendum_code >> # First addendum code
            (
              # Just match all comma-separated values (including "and" as a code)
              (comma >> space >> addendum_code).repeat(1, 50) |
              # Or comma without space
              (comma >> addendum_code).repeat(1, 50)
            ).as(:additional_codes).maybe >> # Entire additional_codes is optional
            optional_suffix.repeat(0, 2)
          ).as(:combined_addenda) |
          # Format 3: ASHRAE Addenda a, b, c to Standard/Guideline X-YYYY (without publisher at start)
          (
            str("Addenda") >> space >>
            addendum_code >> # First addendum code
            (
              (comma >> space >> str("and") >> space >> addendum_code) | # ", and b"
              (space >> str("and") >> space >> addendum_code) |  # "and b"
              (comma >> space >> addendum_code).repeat(1, 20) |  # comma-separated
              (comma >> addendum_code).repeat(1, 20)  # comma without space
            ).repeat(0, 50).as(:additional_codes) >>  # Allow 0 for single addendum
            space >>
            (str("to") | str("for")) >> space >>
            ((str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
              0, 10
            )).as(:copublisher) >> space).maybe >>
            type.as(:type) >> space >>
            code >>
            (dash >> year_digits.as(:year)).maybe >>
            optional_suffix.repeat(0, 2)
          ).as(:combined_addenda) |
          # Format 4: ASHRAE Addenda to Standard/Guideline X-YYYY (without specific codes)
          (
            publisher.as(:publisher) >> space >>
            str("Addenda") >> space >>
            (str("to") | str("for")) >> space >>
            type.as(:type) >> space >>
            code >>
            (dash >> year_digits.as(:year)).maybe >>
            optional_suffix.repeat(0, 2)
          ).as(:combined_addenda) |
          # Format 5: ASHRAE Addenda a, b, c to 105-2007 (missing type keyword)
          (
            publisher.as(:publisher) >> space >>
            str("Addenda") >> space >>
            addendum_code >>
            (
              (comma >> space >> str("and") >> space >> addendum_code) | # ", and b"
              (space >> str("and") >> space >> addendum_code) |  # "and b"
              (comma >> space >> addendum_code).repeat(1, 20) |  # comma-separated
              (comma >> addendum_code).repeat(1, 20)  # comma without space
            ).repeat(0, 50).as(:additional_codes) >>  # Allow 0 for single addendum
            space >>
            (str("to") | str("for")) >> space >>
            code_with_year >>
            optional_suffix.repeat(0, 2)
          ).as(:combined_addenda) |
          # Format 6: Addenda a, b, c to 105-2007 (without publisher, missing type)
          (
            str("Addenda") >> space >>
            addendum_code >>
            (
              (comma >> space >> str("and") >> space >> addendum_code) | # ", and b"
              (space >> str("and") >> space >> addendum_code) |  # "and b"
              (comma >> space >> addendum_code).repeat(1, 20) |  # comma-separated
              (comma >> addendum_code).repeat(1, 20)  # comma without space
            ).repeat(0, 50).as(:additional_codes) >>  # Allow 0 for single addendum
            space >>
            (str("to") | str("for")) >> space >>
            code_with_year >>
            optional_suffix.repeat(0, 2)
          ).as(:combined_addenda) |
          # Format 7: ASHRAE Standard X-YYYY: Addenda a, b, c (colon or space separator)
          (
            publisher.as(:publisher) >> space >>
            type.as(:type) >> space >>
            code >>
            (dash >> year_digits.as(:year)).maybe >>
            ((colon >> space) | space) >>
            str("Addenda") >> space >>
            addendum_code >> # First addendum code
            (
              # Range pattern: "a through z"
              (space >> str("through") >> space >> addendum_code) |
              # Space or comma separated codes (handles typos like "bl bq")
              ((space | (comma >> space)) >> addendum_code).repeat(1, 50) |
              # Just match all comma-separated values
              (comma >> space >> addendum_code).repeat(1, 50) |
              # Or comma without space
              (comma >> addendum_code).repeat(1, 50)
            ).as(:additional_codes).maybe >>
            (space >> additional_copublisher).maybe >>
            addendum_date_suffix.maybe >>
            optional_suffix.repeat(0, 2)
          ).as(:combined_addenda)
      end

      # Year-first Addenda Package pattern
      rule(:year_first_addenda_package_identifier) do
        (
          year_digits.as(:package_year) >> space >>
          (
            # Format 1: "YYYY Addenda Supplement Package to Standard X-YYYY"
            (str("Addenda") >> space >> str("Supplement") >> (space >> str("Package")).maybe >> space >> str("to") >> space >>
              ((str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
                0, 10
              )).as(:copublisher) >> space).maybe >>
              type.as(:type) >> space >> code >> (dash >> year_digits.as(:year)).maybe) |
            # Format 2: "YYYY Supplement Addenda a, b, c to Standard X-YYYY"
            (str("Supplement") >> space >> str("Addenda") >> space >>
              addendum_code >>
              (
                (comma >> space >> addendum_code).repeat(1, 50) |
                (comma >> addendum_code).repeat(1, 50)
              ).as(:additional_codes).maybe >>
              space >> str("to") >> space >>
              ((str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
                0, 10
              )).as(:copublisher) >> space).maybe >>
              type.as(:type) >> space >> code >> (dash >> year_digits.as(:year)).maybe
            ) |
            # Format 3: "YYYY Addenda Supplement to Standard X-YYYY" (without "Package")
            (str("Addenda") >> space >> str("Supplement") >> space >> str("to") >> space >>
              ((str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
                0, 10
              )).as(:copublisher) >> space).maybe >>
              type.as(:type) >> space >> code >> (dash >> year_digits.as(:year)).maybe) |
            # Format 4: "YYYY Supplement to ANSI/ASHRAE/... Standard X-YYYY Errata (date)"
            (str("Supplement") >> space >> str("to") >> space >>
              ((str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
                0, 10
              )).as(:copublisher) >> space).maybe >>
              type.as(:type) >> space >> code >> (dash >> year_digits.as(:year)).maybe >>
              errata_suffix_on_addendum.maybe)
          ) >>
          optional_suffix.repeat(0, 2)
        ).as(:addenda_package)
      end

      # Addenda Package pattern (collection packages)
      rule(:addenda_package_identifier) do
        # Format with copublisher: ANSI/ASHRAE Standard 34-2013 Addenda Supplement Package (...)
        (
          (str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
            0, 10
          )).as(:copublisher) >> space >>
          type.as(:type) >> space >>
          code >>
          (dash >> year_digits.as(:year)).maybe >>
          ((colon >> space) | space) >>
          str("Addenda") >> space >>
          ((str("Supplement") >> (space >> str("Package")).maybe) | str("Package")).as(:package_description) >>
          (space >> str("for") >> space >> year_digits.as(:target_year)).maybe >>
          optional_suffix.repeat(0, 3)
        ).as(:addenda_package) |
          # Format with publisher + comma Addenda YEAR Supplement: ASHRAE Standard 90.1-2010, Addenda 2012 Supplement: Addenda Supplement Package
          (
            publisher.as(:publisher) >> space >>
            type.as(:type) >> space >>
            code >>
            (dash >> year_digits.as(:year)).maybe >>
            comma >> space >> str("Addenda") >> space >> year_digits.as(:package_year) >> space >> str("Supplement") >> colon >> space >>
            str("Addenda") >> space >>
            ((str("Supplement") >> (space >> str("Package")).maybe) | str("Package")).as(:package_description) >>
            optional_suffix.repeat(0, 3)
          ).as(:addenda_package) |
          # Standard format with publisher: ASHRAE Standard X-YYYY Addenda Supplement Package
          (
            publisher.as(:publisher) >> space >>
            type.as(:type) >> space >>
            code >>
            (dash >> year_digits.as(:year)).maybe >>
            (space >> year_digits.as(:package_year)).maybe >>
            additional_copublisher.maybe >>
            suffix.maybe >>
            reaffirmed.maybe >>
            ((colon >> space) | space) >>
            str("Addenda") >> space >>
            ((str("Supplement") >> (space >> str("Package")).maybe) | str("Package")).as(:package_description) >>
            (space >> str("for") >> space >> year_digits.as(:target_year)).maybe >>
            optional_suffix.repeat(0, 3)
          ).as(:addenda_package)
      end

      # Addendum date pattern (Month Day, Year - e.g., "January 22, 2019")
      rule(:addendum_date_suffix) do
        space >> lparen >> month_name >> space >> digit.repeat(1,
                                                               2) >> comma.maybe >> (space | comma.maybe) >> year_digits >> rparen
      end

      # Addendum pattern (multiple formats):
      rule(:addendum_identifier) do
        # Format: ASHRAE Addendum X to Standard/Guideline X-YYYY
        (
          publisher.as(:publisher) >> space >>
          str("Addendum") >> space >>
          addendum_code >>
          space >>
          (str("to") | str("for")) >> space >>
          type.as(:type) >> space >>
          code >>
          (dash >> year_digits.as(:year)).maybe >>
          additional_copublisher.maybe >>
          addendum_date_suffix.maybe >>
          errata_suffix_on_addendum.maybe >>
          optional_suffix.repeat(0, 2)
        ).as(:publisher_addendum) |
          # Format: ASHRAE Addendum X to ASHRAE Standard/Guideline X-YYYY (same publisher repeated)
          (
            publisher.as(:publisher) >> space >>
            str("Addendum") >> space >>
            addendum_code >>
            space >>
            (str("to") | str("for")) >> space >>
            publisher.as(:base_publisher) >> space >>
            type.as(:type) >> space >>
            code >>
            (dash >> year_digits.as(:year)).maybe >>
            additional_copublisher.maybe >>
            addendum_date_suffix.maybe >>
            errata_suffix_on_addendum.maybe >>
            optional_suffix.repeat(0, 2)
          ).as(:publisher_base_addendum) |
          # Format: ASHRAE Addendum X to ANSI/ASHRAE Standard/Guideline X-YYYY (ASHRAE publisher + copublisher base)
          (
            publisher.as(:publisher) >> space >>
            str("Addendum") >> space >>
            addendum_code >>
            space >>
            (str("to") | str("for")) >> space >>
            (
              (str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
                0, 10
              )).as(:copublisher) >>
              space
            ) >>
            type.as(:type) >> space >>
            code >>
            (dash >> year_digits.as(:year)).maybe >>
            addendum_date_suffix.maybe >>
            errata_suffix_on_addendum.maybe >>
            optional_suffix.repeat(0, 2)
          ).as(:publisher_addendum_copublisher) |
          # Format: ASHRAE Addendum X to ANSI/ASHRAE 62.1-2022 (publisher + copublisher, no type)
          (
            publisher.as(:publisher) >> space >>
            str("Addendum") >> space >>
            addendum_code >>
            space >>
            (str("to") | str("for")) >> space >>
            (
              (str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
                0, 10
              )).as(:copublisher) >>
              space
            ) >>
            code_with_year >>
            additional_copublisher.maybe >>
            addendum_date_suffix.maybe >>
            errata_suffix_on_addendum.maybe >>
            optional_suffix.repeat(0, 2)
          ).as(:publisher_addendum_copublisher_no_type) |
          # Format: [ANSI/ASHRAE] Addendum X to/for [ANSI/ASHRAE] 34-2024 (no type)
          (
            (
              (str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
                0, 10
              )).as(:copublisher) >>
              space
            ).maybe >>
            str("Addendum") >> space >>
            addendum_code >>
            space >>
            (str("to") | str("for")) >> space >>
            (
              (str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
                0, 10
              )).as(:copublisher) >>
              space
            ).maybe >> # Make second copublisher optional
            code_with_year >>
            additional_copublisher.maybe >>
            addendum_date_suffix.maybe >>
            errata_suffix_on_addendum.maybe >>
            optional_suffix.repeat(0, 2)
          ).as(:addendum_no_type) |
          # Format: [ANSI/ASHRAE] Addendum X to/for [ANSI/ASHRAE] Standard/Guideline X-YYYY
          (
            (
              (str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
                0, 10
              )).as(:copublisher) >>
              space
            ).maybe >>
            str("Addendum") >> space >>
            addendum_code >>
            space >>
            (str("to") | str("for")) >> space >>
            (
              (str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
                0, 10
              )).as(:copublisher) >>
              space
            ).maybe >>
            type.as(:type) >> space >>
            code >>
            (dash >> year_digits.as(:year)).maybe >>
            additional_copublisher.maybe >>
            addendum_date_suffix.maybe >>
            errata_suffix_on_addendum.maybe >>
            optional_suffix.repeat(0, 2)
          ).as(:addendum) |
          # Format: ASHRAE Standard 15-2013 Addendum a
          (
            publisher.as(:publisher) >> space >>
            type.as(:type) >> space >>
            code >>
            (dash >> year_digits.as(:year)).maybe >>
            additional_copublisher.maybe >>
            suffix.maybe >>
            reaffirmed.maybe >>
            ((colon >> space) | space) >>
            (str("Addendum") | str("addendum")) >> space >>
            addendum_code >>
            addendum_date_suffix.maybe >>
            errata_suffix_on_addendum.maybe >>
            optional_suffix.repeat(0, 2)
          ).as(:standard_addendum) |
          # Format: ASHRAE Standard 15-2013 Addendum a (with lowercase and space only)
          (
            publisher.as(:publisher) >> space >>
            type.as(:type) >> space >>
            code >>
            (dash >> year_digits.as(:year)).maybe >>
            additional_copublisher.maybe >>
            suffix.maybe >>
            reaffirmed.maybe >>
            space >>
            (str("Addendum") | str("addendum")) >> space >>
            addendum_code >>
            addendum_date_suffix.maybe >>
            errata_suffix_on_addendum.maybe >>
            optional_suffix.repeat(0, 2)
          ).as(:standard_addendum)
      end

      # Main identifier pattern
      rule(:identifier) do
        errata_identifier |
          interpretation_identifier |
          combined_addenda_identifier |
          year_first_addenda_package_identifier |
          addenda_package_identifier |
          addendum_identifier |
          # Standalone copublisher pattern (ANSI/AMCA 210-99, AMCA 210-99).
          # The literal "ASHRAE" is excluded here so a bare "ASHRAE <code>-<year>"
          # is not swallowed as a copublisher and instead falls through to the
          # ASHRAE-publisher branch below.
          (((str("ANSI") >> slash).maybe >> (str("ASHRAE").absent? >> letter).repeat(2,
                                                                                     10)).as(:copublisher) >>
            space >>
            code_with_year >>
            optional_suffix.repeat(0, 2)) |
          # Copublished patterns without type (ANSI/ASHRAE 34-2024)
          ((str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
            0, 10
          )).as(:copublisher) >>
            space >>
            code_with_year >>
            (space >> additional_copublisher).maybe >>
            suffix.maybe >>
            reaffirmed.maybe >>
            optional_suffix.repeat(0, 2)) |
          # Copublished patterns with type (ANSI/ASHRAE, ANSI/ASHRAE/ACCA, ANSI/ASHRAE/ASHE/ICC, etc.)
          ((str("ANSI") >> slash >> str("ASHRAE") >> (slash >> letter.repeat(3, 10)).repeat(
            0, 10
          )).as(:copublisher) >>
            space >>
            type.as(:type).maybe >> space.maybe >>
            code >>
            (space?.maybe >> dash >> year_digits.as(:year)).maybe >>
            (space >> additional_copublisher).maybe >>
            suffix.maybe >>
            reaffirmed.maybe >>
            optional_suffix.repeat(0, 2)) |
          # Standard ASHRAE pattern. The type keyword is optional so a bare
          # partial reference "ASHRAE <code>" (no "Standard"/"Guideline") parses;
          # the builder defaults the absent type to "Standard".
          (publisher.as(:publisher) >> space >>
            (type.as(:type) >> space).maybe >>
            code >>
            (space?.maybe >> dash >> year_digits.as(:year)).maybe >>
            (space >> additional_copublisher).maybe >>
            suffix.maybe >>
            reaffirmed.maybe >>
            optional_suffix.repeat(0, 2)
          ).as(:base)
      end

      root(:identifier)

      def self.parse(string)
        if string.length > Pubid::MAX_INPUT_LENGTH
          raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        # Strip leading/trailing whitespace
        cleaned = string.strip

        # Handle fixture format: !original!canonical
        # Extract just the original identifier for parsing
        if cleaned.start_with?("!")
          parts = cleaned.split("!")
          # Format: "" (before first !) + "original" + "canonical"
          cleaned = parts[1] if parts.size >= 3
        end

        # Normalize multiple spaces to single space
        cleaned = cleaned.gsub(/\s+/, " ")

        # Normalize reaffirmation patterns
        cleaned = cleaned.gsub(/\(RA\s+(\d{4})\)/, "(RA \\1)")
        cleaned = cleaned.gsub(/RA\s+(\d{4})/, "RA \\1")

        # Remove trailing periods and commas
        cleaned = cleaned.gsub(/[,.]$/, "")

        # Remove trailing double parentheses (typos in source data)
        cleaned = cleaned.gsub("))", ")")

        # Fix unclosed trailing parenthesis (data truncation issue)
        open_count = cleaned.count("(")
        close_count = cleaned.count(")")
        if open_count > close_count
          cleaned += ")" * (open_count - close_count)
        end

        # Normalize dash patterns (remove space around dash in year/code)
        cleaned = cleaned.gsub(/-\s+/, "-")
        cleaned = cleaned.gsub(/\s+/, " ") # Clean up any double spaces created

        # Preprocess ", and" and " and" patterns in addenda code lists
        # This fixes greedy matching where "and" gets consumed as a code
        # Only replace "and" in code lists (between Addendum/Addenda and to/for/(end)
        # NOT in descriptive text that follows
        if cleaned =~ /\bAddenda\s+/ || cleaned =~ /\bAddendum\s+/
          # Find the boundary where code list ends (to, for, or opening paren)
          boundary_pattern = /\s+(?:to|for|\()/
          boundary_match = cleaned.match(boundary_pattern)

          if boundary_match
            # Only replace "and" in the portion before the boundary
            boundary_pos = cleaned.index(boundary_match[0])
            before_boundary = cleaned[0...boundary_pos]
            after_boundary = cleaned[boundary_pos..]

            # Replace ", and" and " and" in the code list portion only
            before_boundary = before_boundary.gsub(/,\s+and\s+/i, ", ")
            before_boundary = before_boundary.gsub(/\s+and\s+/i, ", ")

            cleaned = before_boundary + after_boundary
          else
            # No boundary found, apply to entire string
            cleaned = cleaned.gsub(/,\s+and\s+/i, ", ")
            cleaned = cleaned.gsub(/\s+and\s+/i, ", ")
          end

          # Normalize "Addendum" to "Addenda" when followed by multiple codes (comma-separated)
          # Pattern: "Addendum a, b" -> "Addenda a, b"
          cleaned = cleaned.gsub(/\bAddendum\s+([a-z]+)\s*,\s*/i,
                                 "Addenda \\1, ")
        end

        new.parse(cleaned)
      end
    end
  end
end
