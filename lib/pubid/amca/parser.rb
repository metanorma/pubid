# frozen_string_literal: true

module Pubid
  module Amca
    # Parser class for ACMA identifiers
    # Single Responsibility: Parsing ACMA identifier syntax
    class Parser < Parslet::Parser
      # Basic building blocks
      rule(:space) { str(" ") }
      rule(:space?) { space.maybe }
      rule(:dash) { str("-") }
      rule(:slash) { str("/") }
      rule(:lparen) { str("(") }
      rule(:rparen) { str(")") }
      rule(:dot) { str(".") }

      rule(:digit) { match("[0-9]") }
      rule(:digits) { digit.repeat(1) }
      rule(:letter) { match("[A-Za-z]") }

      # Year pattern (2 digits starting with 0-1, or 4 digits starting with 19 or 20)
      rule(:year_digits) do
        ((str("19") | str("20")) >> digit.repeat(2, 2)) |
          digit.repeat(2, 2)
      end

      # Copublisher (ANSI/AMCA or AMCA)
      rule(:copublisher) do
        (str("ANSI") >> slash >> str("AMCA")) |
          str("AMCA")
      end

      # Additional copublisher after year (e.g., /ASHRAE 51-16)
      rule(:additional_copublisher) do
        slash >> letter.repeat(2,
                               10) >> space >> digits >> (dash >> digits).maybe
      end

      # Code pattern (e.g., 210, 500-D, 99, 204)
      rule(:code) do
        (
          digits >> # Main number
          (dash >> letter).maybe >> # Optional letter suffix (500-D)
          (dot >> digits).maybe # Optional decimal (not in fixtures but possible)
        ).as(:code)
      end

      # Type (Standard or Publication)
      rule(:type) do
        str("Standard") | str("Publication")
      end

      # Reaffirmation year (R2008, R2010, etc.)
      # Bare parenthesised year, e.g. "(2010)"
      rule(:paren_year) { lparen >> digits.as(:reaffirmed) >> rparen }

      rule(:reaffirmation) do
        lparen >> str("R") >> digits.as(:reaffirmed) >> rparen
      end

      # Suffix
      rule(:suffix) do
        str("R") | str("P")
      end

      # Publication revision (Rev. 01-23)
      rule(:revision) do
        lparen >> str("Rev") >> dot.maybe >> space >> digits.as(:revision_year) >> dash >> digits >> rparen
      end

      # Interpretation code (JW, KB, RG, AW, AH, or just a number)
      rule(:interpretation_code) do
        letter.repeat(2).as(:interpretation_code) | # Two-letter code
          digits.as(:interpretation_code) # Number
      end

      # Interpretation keyword
      rule(:interp_keyword) do
        space >> str("Interp")
      end

      # Main identifier rule
      rule(:identifier) do
        # Interpretation patterns (must come first as they're more specific)
        interpretation_identifier |
          # Publication patterns
          publication_identifier |
          # Standard patterns (must come last as they're the most general)
          standard_identifier
      end

      # Interpretation pattern (e.g., AMCA 99 JW Interp, AMCA 204 – 1)
      rule(:interpretation_identifier) do
        (
          copublisher.as(:copublisher).maybe >> space >>
          code >>
          space >>
          # Either a letter code (JW, KB, etc.) or a dash-number pattern
          (
            (interpretation_code >> interp_keyword) |
            ((str("–") | str("-")) >> space.maybe >> digits.as(:interpretation_year) >> interp_keyword.maybe) |
((str("–") | str("-")) >> space.maybe >> interpretation_code)
          )
        ).as(:interpretation) |
          # Simple interpretation: AMCA 511 Interp
          (
            copublisher.as(:copublisher).maybe >> space >>
            code >>
            interp_keyword
          ).as(:interpretation)
      end

      # Publication pattern (e.g., AMCA Publication 211-22 (Rev. 01-23))
      rule(:publication_identifier) do
        (
          copublisher.as(:copublisher).maybe >> space >>
          str("Publication").as(:publication_keyword) >> space >>
          code >>
          (space.maybe >> dash >> year_digits.as(:year)).maybe >>
          (space >> revision).maybe >>
          (space >> (reaffirmation | paren_year)).maybe
        ).as(:publication)
      end

      # Standard pattern (e.g., ANSI/AMCA 210-16, ANSI/AMCA Standard 99-25)
      rule(:standard_identifier) do
        (
          copublisher.as(:copublisher).maybe >> space >>
          type.as(:type).maybe >> space.maybe >>
          code >>
          (space.maybe >> dash >> year_digits.as(:year)).maybe >>
          (space >> additional_copublisher).maybe >>
          suffix.maybe >>
          (space >> (reaffirmation | paren_year)).maybe
        ).as(:standard)
      end

      root(:identifier)

      def self.parse(string)
        # Strip leading/trailing whitespace
        cleaned = string.strip

        # Normalize multiple spaces to single space
        cleaned = cleaned.gsub(/\s+/, " ")

        # Normalize en dash to regular dash
        cleaned = cleaned.gsub("–", "-")

        # Remove trailing periods and commas
        cleaned = cleaned.gsub(/[,.]$/, "")

        new.parse(cleaned)
      end
    end
  end
end
