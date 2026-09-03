# frozen_string_literal: true

module Pubid
  module Jcgm
    # Parses JCGM URNs back into identifiers.
    #
    # Identifiers are rebuilt **directly from the URN segments** rather than
    # rendered to a human-readable string and re-parsed (the BIPM UrnParser
    # pattern). Round-tripping through the grammar flattened the segments into
    # one string and silently lost everything the string form could not carry:
    # a GUM guide (`urn:jcgm:gum.6:2020`) raised, and the language and
    # supplement segments were dropped, so a corrigendum read back as the
    # standard it amends — a different document, with no error.
    #
    # Shapes emitted by UrnGenerator, and read back here:
    #   urn:jcgm:200:2008                        → JCGM 200:2008
    #   urn:jcgm:100:2008:en                     → JCGM 100:2008(E)
    #   urn:jcgm:200:2012:en,fr                  → JCGM 200:2012(E/F)
    #   urn:jcgm:GUM                             → JCGM GUM
    #   urn:jcgm:gum.6:2020                      → JCGM GUM-6:2020
    #   urn:jcgm:200:2008:corrigendum            → JCGM 200:2008 Corrigendum
    #   urn:jcgm:101:2008:corrigendum:1:2009     → JCGM 101:2008/Cor 1:2009
    #   urn:jcgm:100:2008:amendment:1:2023       → JCGM 100:2008/Amd 1:2023
    #   urn:jcgm:meeting:17:2012                 → JCGM 17th Meeting (2012)
    #   urn:jcgm:meeting:11                      → JCGM 11st Meeting
    #
    # KNOWN GAP, on the generator side and unchanged here: a full date is
    # rendered as its year alone (`JCGM GUM-1:2022-11-28` →
    # `urn:jcgm:gum.1:2022`), so a URN cannot restore the month and day.
    # Widening it would change already-published URNs.
    class UrnParser < Pubid::UrnParser::Base
      MEETING_MARKER = "meeting"

      # The GUM-guide number is written "gum.<n>" by UrnGenerator.
      GUM_PREFIX = "gum."

      # The supplement marker UrnGenerator writes is the typed stage's
      # `type_code`; the abbreviation is what `Jcgm.locate_stage` matches on.
      SUPPLEMENT_ABBRS = {
        "corrigendum" => "Cor",
        "amendment" => "Amd",
      }.freeze

      MEETING_ABBR = "Meeting"

      # Mirrors `year_digits` in the shared parser rules.
      YEAR_PATTERN = /\A(?:19|20)\d{2}\z/

      # A language segment is one or more comma-joined ISO codes.
      LANGUAGES_PATTERN = /\A[a-z]{2}(?:,[a-z]{2})*\z/

      # Language codes back to the single-letter form the identifier prints;
      # the builder maps the other way when parsing "(E)" / "(E/F)".
      LANGUAGE_LETTERS = Pubid::Builder::Base::LANG_CHAR_MAP.invert.freeze

      def parse_urn(urn)
        parts = split_parts(strip_namespace(urn))
        return parse_meeting_urn(parts) if parts.first == MEETING_MARKER

        parse_document_urn(parts)
      end

      private

      # urn:jcgm:meeting:<number>[:<year>] -> Identifiers::Meeting
      #
      # The reconstruction must agree with a parsed identifier attribute for
      # attribute, so `typed_stage` comes from the same registry lookup
      # `Builder#locate_typed_stage` uses — NOT from the attribute default,
      # which additionally sets `original_abbr` and would make a
      # URN-reconstructed meeting unequal to a parsed one.
      def parse_meeting_urn(parts)
        _, number, year = parts

        Identifiers::Meeting.new(
          number: meeting_number(number),
          date: urn_date(year),
          typed_stage: Jcgm.locate_stage(MEETING_ABBR),
        )
      end

      # A guide, a GUM guide, or a supplement wrapping one of those. The
      # supplement marker splits the segments: everything before it describes
      # the base document, everything after is the supplement's own number and
      # date.
      def parse_document_urn(parts)
        marker_at = parts.index { |segment| SUPPLEMENT_ABBRS.key?(segment) }
        return build_document(parts) unless marker_at

        build_supplement(
          parts[marker_at],
          build_document(parts[0...marker_at]),
          parts[(marker_at + 1)..] || [],
        )
      end

      # The class comes from the same registry the builder uses, so a URN and a
      # parsed reference resolve to one class and one typed_stage.
      def build_supplement(marker, base, tail)
        typed_stage = Jcgm.locate_stage(SUPPLEMENT_ABBRS.fetch(marker))
        number, year = tail

        Jcgm.locate_type(typed_stage.type_code).new(
          base: base,
          number: (number.nil? || number.empty? ? nil : build_code(number)),
          date: urn_date(year),
          typed_stage: typed_stage,
        )
      end

      # <number>[:<year>][:<languages>] — the number segment carries the
      # "gum." prefix for a GUM guide, which is what selects the class.
      #
      # Guide and GumGuide deliberately take their `typed_stage` from the
      # attribute default: the grammar emits no type token for them, so
      # `Builder#build` fills it from `published_typed_stage` too, and both
      # paths agree.
      def build_document(parts)
        number, *rest = parts
        require_number!(number)
        gum = number.start_with?(GUM_PREFIX)

        (gum ? Identifiers::GumGuide : Identifiers::Guide).new(
          number: build_code(gum ? number.delete_prefix(GUM_PREFIX) : number),
          date: urn_date(segment_matching(rest, YEAR_PATTERN)),
          languages: urn_languages(segment_matching(rest, LANGUAGES_PATTERN)),
        )
      end

      def require_number!(segment)
        return unless segment.nil? || segment.empty?

        raise Pubid::UrnParser::Errors::ParseError,
              "JCGM URN has no document number"
      end

      def segment_matching(segments, pattern)
        segments.find { |segment| segment.match?(pattern) }
      end

      # The ordinal, normalized the way `Identifiers::Meeting.ordinal` does it
      # (`number.to_i`), so "011" reads back as "11" and a missing or
      # non-numeric segment as "0" — the behaviour of the previous
      # render-and-re-parse implementation.
      def meeting_number(segment)
        build_code(segment.to_i.to_s)
      end

      def build_code(value)
        Pubid::Components::Code.new(value: value.to_s)
      end

      # nil for an absent year; a Date for a well-formed one. The grammar
      # accepts only a 19xx/20xx year, so anything else is a malformed URN and
      # must still be rejected now that no re-parse validates it.
      def urn_date(segment)
        return nil if segment.nil? || segment.empty?

        unless segment.match?(YEAR_PATTERN)
          raise Pubid::UrnParser::Errors::ParseError,
                "Invalid year in JCGM URN: #{segment.inspect}"
        end

        Pubid::Components::Date.new(year: segment)
      end

      # "en" -> (E), "en,fr" -> (E/F). `original_code` is what the renderer
      # prints, so it is restored from the code rather than left nil.
      def urn_languages(segment)
        return nil if segment.nil? || segment.empty?

        segment.split(",").map do |code|
          Pubid::Components::Language.new(
            code: code,
            original_code: LANGUAGE_LETTERS.fetch(code, code),
          )
        end
      end
    end
  end
end
