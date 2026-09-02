# frozen_string_literal: true

module Pubid
  module Iso
    # Applies pre-parse normalizations to ISO identifier strings, then dispatches
    # to the parser/builder. Handles Cyrillic (Russian) translations, legacy
    # update_codes regex rewrites, and the DAD/FDAM pattern that the PEG
    # parser cannot recognize because it treats "/" as a copublisher separator.
    class Normalizer
      DAD_PATTERN = /^(.+?)\/(F?DAD)\s+(\d+)(?::(\d{4}))?$/.freeze

      class << self
        # Apply all normalizations to an identifier string and return the
        # parsed identifier object.
        # @param identifier [String]
        # @return [Pubid::Iso::Identifier]
        def apply(identifier)
          if (match = identifier.match(DAD_PATTERN))
            parse_dad_pattern(match)
          else
            normalized = Core::UpdateCodes.apply(identifier, :iso)
            normalized = normalize_cyrillic(normalized)
            normalized = normalized.gsub(
            /\bGuide\s+(ISO)(?!\/)/i,
            '\1 Guide'
          )
            parse_with_builder(normalized)
          end
        end

        private

        def parse_with_builder(string)
          parsed = Pubid::Iso.parser.parse(string)
          Pubid::Iso.builder.build(parsed)
        end

        # Normalize Cyrillic (Russian) ISO identifiers to Latin equivalents.
        # ИСО = ISO, МЭК = IEC, Руководство/Руководства = Guide,
        # ОПМС = FDIS, ПМС = DIS, ТО = TR, ТС = TS.
        # @return [String]
        def normalize_cyrillic(identifier)
          return identifier unless identifier.match?(/[а-яА-Я]/)

          normalized = identifier.dup
          # Remove inline comments (Russian style comments with #)
          normalized = normalized.gsub(/\s*#\s*.*$/, "")
          # Translate Russian abbreviations (order matters: longer first)
          normalized = normalized.gsub("Руководства", "GUIDE")
          normalized = normalized.gsub("Руководство", "GUIDE")
          # Guide-first spellings (e.g. "Guide ISO 34:2009") normalize to
          # publisher-first so the type grammar can match
          normalized = normalized.gsub(
              /\bGUIDE\s+(ISO)(?!\/)/,
              '\1 GUIDE'
            )

          normalized = normalized.gsub("ИСО/МЭК", "ISO/IEC")
          normalized = normalized.gsub("ИСО/ОПМС", "ISO/FDIS")
          normalized = normalized.gsub("ИСО/ПМС", "ISO/DIS")
          normalized = normalized.gsub("ИСО/ТО", "ISO/TR")
          normalized = normalized.gsub("ИСО/ТС", "ISO/TS")
          normalized = normalized.gsub("ИСО", "ISO")
          normalized = normalized.gsub("МЭК", "IEC")
          # Standalone Cyrillic stage abbreviations (after publisher replacements)
          normalized = normalized.gsub("ТО", "TR")
          normalized = normalized.gsub("ТС", "TS")
          normalized = normalized.gsub("ОПМС", "FDIS")
          normalized = normalized.gsub("ПМС", "DIS")
          normalized.strip
        end

        # Parse the DAD/FDAM pattern manually. The parser fails because it
        # treats "/" as a copublisher separator.
        # Pattern: "ISO 2631/DAD 1" or "ISO 2553/DAD 1:1987"
        def parse_dad_pattern(match)
          base_str = match[1]          # "ISO 2631" or "ISO 2553"
          stage_abbr = match[2]        # "DAD" or "FDAD"
          supplement_number = match[3] # "1"
          supplement_year = match[4]   # "1987" or nil

          base_parsed = Pubid::Iso.parser.parse(base_str)
          base = Pubid::Iso.builder.build(base_parsed)

          addendum = Identifiers::Addendum.new
          addendum.base = base
          addendum.number = Iso::Components::Code.new(value: supplement_number)
          addendum.date = Pubid::Components::Date.new(year: supplement_year) if supplement_year

          typed_stage = Pubid::Iso.locate_stage(stage_abbr)
          addendum.typed_stage = typed_stage
          addendum.stage = typed_stage.to_stage
          addendum.type = typed_stage.to_type

          addendum
        end
      end
    end
  end
end
