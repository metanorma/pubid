# frozen_string_literal: true

require "parslet"

module Pubid
  module Jcgm
    class Parser < Parslet::Parser
      include ::Pubid::Parser::CommonParseRules
      include ::Pubid::Parser::CommonParseMethods

      root :identifier

      rule(:identifier) do
        meeting_identifier | amendment_identifier | corrigendum_identifier |
          numbered_corrigendum_identifier | base | named_guide_identifier
      end

      # "JCGM 200:2008 Corrigendum" — a base guide plus a trailing
      # " Corrigendum" word (no number). Must precede base: Parslet
      # is an ordered PEG that commits to the first matching alternative, so if
      # base ran first it would consume "JCGM 200:2008" and root
      # would fail on the leftover " Corrigendum". Emits type_with_stage so the
      # builder routes it to Corrigendum.
      rule(:corrigendum_identifier) do
        base.as(:base) >> space >>
          str("Corrigendum").as(:type_with_stage)
      end

      # "JCGM 101:2008/Cor 1:2009" — a base guide plus a slash-separated
      # numbered corrigendum (mirrors the ISO/IEC supplement form). The
      # trailing :YYYY is optional so "JCGM 101:2008/Cor 1" also parses.
      # Must precede base for the same PEG-commit reason as corrigendum_identifier.
      rule(:numbered_corrigendum_identifier) do
        base.as(:base) >>
          str("/") >> str("Cor").as(:type_with_stage) >>
          space >> digits.as(:number) >>
          corrigendum_date.maybe
      end

      # Dateless "named" guides: "JCGM GUM", "JCGM VIM-3" (and future "VIM-N").
      # Last in the alternation — only reached when base fully fails
      # (these have no date, so number_portion/date_portion never match).
      rule(:named_guide_identifier) do
        publisher >> space >> named_number
      end

      rule(:named_number) do
        (str("GUM") | (str("VIM") >> (str("-") >> digits).maybe)).as(:number)
      end

      # Committee/meeting record, e.g. "JCGM 17th Meeting (2012)". Diverges
      # from base right after the digits (base wants ":", meeting
      # wants the ordinal suffix), so ordered choice is unambiguous. Emits the
      # same tokens as a guide plus type_with_stage "Meeting", so the generic
      # builder path resolves it to Identifiers::Meeting (like "Amd").
      rule(:meeting_identifier) do
        publisher >> space >> digits.as(:number) >> ordinal_suffix >>
          space >> str("Meeting").as(:type_with_stage) >> space >>
          str("(") >> year_digits.as(:date) >> str(")")
      end

      rule(:ordinal_suffix) do
        str("st") | str("nd") | str("rd") | str("th")
      end

      # `date_portion` is optional so a partial reference that omits the
      # trailing `:YYYY` date (e.g. "JCGM 100") parses with `date` left nil,
      # letting relaton match a collection via `matches?(row, ignore: [:date])`.
      # The whole sub-rule is `.maybe` (not the year inside it) so a dangling
      # ":" still fails. Mirrors ETSI (lib/pubid/etsi/parser.rb).
      rule(:base) do
        publisher >> space >> number_portion >>
          date_portion.maybe >> language_portion.maybe
      end

      rule(:amendment_identifier) do
        base.as(:base) >>
          str("/") >> amendment_type >>
          space >> digits.as(:number) >>
          amendment_date.maybe
      end

      rule(:publisher) do
        str("JCGM").as(:publisher)
      end

      # Number can be plain (100, 200) or GUM-prefixed (GUM-1, GUM-6)
      rule(:number_portion) do
        gum_number | standard_number
      end

      rule(:standard_number) do
        digits.as(:number)
      end

      rule(:gum_number) do
        str("GUM-") >> digits.as(:gum_number)
      end

      # Date can be YYYY or YYYY-MM-DD
      rule(:date_portion) do
        str(":") >> (full_date | year_only)
      end

      rule(:year_only) do
        year_digits.as(:date)
      end

      rule(:full_date) do
        (year_digits >> str("-") >> month_digits >> str("-") >> day_digits).as(:date)
      end

      # Language: "(E)", "(F)", "(E/F)", "(F/E)"
      rule(:language_portion) do
        str("(") >>
          (
            # Multi-language: E/F, F/E
            (str("E/F") | str("F/E")) |
            # Single language: E, F, R, etc.
            match("[A-Z]")
          ).as(:languages) >>
          str(")")
      end

      # Amendment support
      rule(:amendment_type) do
        str("Amd").as(:type_with_stage)
      end

      rule(:amendment_number) do
        digits.as(:number)
      end

      rule(:amendment_date) do
        str(":") >> (full_date | year_only)
      end

      # Numbered corrigendum date: same shape as amendment_date.
      rule(:corrigendum_date) do
        str(":") >> (full_date | year_only)
      end
    end
  end
end
