# frozen_string_literal: true

module Pubid
  module Nist
    # Owns all regex-based normalization applied to NIST identifier strings
    # before the Parslet grammar sees them.
    #
    # The Parser entry point delegates to Preprocessor#call; the grammar
    # itself never inspects raw user input. Each private method below is a
    # named stage of normalization, applied in the order declared in #call.
    # Stages are kept in the historically validated sequence — reordering
    # them risks regressions because later stages often match patterns
    # produced by earlier ones.
    #
    # Format detection (:mr vs :short) is also owned here because it is a
    # property of the original input, not of the parsed tree.
    class Preprocessor
      # Outcome of preprocessing.
      # cleaned - the normalized identifier string ready for the grammar
      # format  - :mr if the input uses dot-separators, :short otherwise
      Result = Struct.new(:cleaned, :format, keyword_init: true)

      # Convert Roman numerals to Arabic numbers per NIST spec.
      ROMAN_TO_ARABIC = {
        "I" => "1",
        "II" => "2",
        "III" => "3",
        "IV" => "4",
        "V" => "5",
        "VI" => "6",
        "VII" => "7",
        "VIII" => "8",
        "IX" => "9",
        "X" => "10",
      }.freeze

      def initialize(input)
        @input = input.to_s.strip
        @cleaned = Core::UpdateCodes.apply(@input, :nist)
      end

      # Run every normalization stage and return a Result.
      #
      # Stage order is load-bearing — later stages match patterns produced
      # by earlier ones. Reordering requires running the full NIST fixture
      # suite to verify no regression.
      def call
        run_stages
        Result.new(cleaned: @cleaned, format: detected_format)
      end

      # Sequence of normalization stages in historically validated order.
      # Extracted so rubocop can scope length/ABC metrics narrowly.
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def run_stages
        normalize_spurious_u_suffix!
        normalize_publisher_and_series!
        normalize_lcirc_supplement_contexts!
        normalize_revision_spacing!
        normalize_letter_suffix_casing!
        normalize_draft_and_volume!
        convert_roman_volumes!
        normalize_supplement_and_part!
        normalize_version_notation!
        normalize_edition_year_suffix!
        normalize_revision_with_letter!
        normalize_version_dotted_spaces!
        normalize_update_markers!
        normalize_supplement_variants!
        normalize_revision_language!
        normalize_mr_translation_codes!
        convert_dashyear_to_edition!
        revert_dashyear_for_series!
        normalize_version_verbose!
        normalize_part_notation!
        normalize_series_specific_spacing!
        normalize_verbose_keywords!
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      # Detect input format: :mr (dot-separated machine-readable) or :short.
      def detected_format
        @input.include?(".") && !@input.match?(/\s/) ? :mr : :short
      end

      private

      # Strip the spurious "U" a bad v2 data migration prefixed onto real
      # letter/revision suffixes (e.g. "800-38a" → "800-38Ua",
      # "73-197r" → "73-197Ur"). NIST's authoritative records
      # (allrecords.xml, DOIs) carry no such "U"; it exists only in the
      # migrated corpus. Removing it here lets the remainder parse through
      # the normal letter-suffix / revision path — "U<letter>" is never a
      # real NIST suffix, so this only ever undoes the corruption.
      def normalize_spurious_u_suffix!
        @cleaned = @cleaned.gsub(/(\d)U([a-z])/, '\1\2')
      end

      # Lowercase publishers, publisher+series concatenations, lowercase
      # series codes, and the lone "LC" → "LCIRC" expansion.
      def normalize_publisher_and_series!
        @cleaned = @cleaned.sub(/^nbs\b/i, "NBS")
        @cleaned = @cleaned.sub(/^nist\b/i, "NIST")
        @cleaned = @cleaned.gsub(
          /^(NBS|NIST)(IR|FIPS|GCR|HB|MONO|MP|NCSTAR|NSRDS)/i, '\1 \2'
        )
        @cleaned = @cleaned.sub(/\b(ir|sp|tn|hb|fips|ams|vts)\b/i, &:upcase)
        @cleaned = @cleaned.gsub(/\bLC\b(?!IRC)/, "LCIRC")
      end

      # LCIRC series: combine with NBS prefix when a supplement marker
      # follows, and convert MR-format dots to spaces so the grammar's
      # circ_supplement_identifier rule can match.
      def normalize_lcirc_supplement_contexts!
        @cleaned = @cleaned.gsub(
          /\bNBS LCIRC\b(?=.*\b(?:supp?|sup\+|r\d+\/)\d)/, "NBS.LCIRC"
        )
        @cleaned = @cleaned.gsub(
          /\bNBS\.LCIRC\.(\d+r\d+\/\d{4})/, "NBS LCIRC \\1"
        )
        @cleaned = @cleaned.gsub(/\bNBS\.LCIRC\.(\d+r\d+)\b/, "NBS LCIRC \\1")
      end

      # Separate revision markers from adjacent digits. LCIRC and CIRC
      # series keep their compact revision form because their grammar
      # rules expect it.
      def normalize_revision_spacing!
        @cleaned = @cleaned.gsub(/([-\d]+[IVX]+[-\d]+)\s+(\d+)/, '\1.\2')
        @cleaned = @cleaned.gsub(/(?<!e)(\d)(rev\d{4})/, '\1 \2')
        # Re-parse round-trip: fold dotted edition-date back to canonical
        # "rev" form so pubid can re-read its own output.
        @cleaned = @cleaned.gsub(/(\d+e\d+)\.([A-Za-z]{3,9}\d{4})/, '\1rev\2')
        # IR revision with slash+year is a V1 Update, not a revision.
        # Must run BEFORE the LCIRC slash rule below so it never adds
        # a space here.
        normalize_ir_slash_year_to_update!
        unless @cleaned.include?("LCIRC") || @cleaned.include?("CIRC")
          @cleaned = @cleaned.gsub(/(\d)(r\d+\/\d{4})/, '\1 \2')
        end
        @cleaned = @cleaned.gsub(/\b(r(?!v)\d{4})\b/, ' \1')
        @cleaned = @cleaned.gsub(/(\d)(r[A-Z][a-z]{2,8}\d{4})/, '\1 \2')
      end

      # "5058r04/98" → "5058/Upd1-199804" (mirrors archived v1 NistIr
      # parser). A 2-digit year normalizes to 19YY. Only applies to IR
      # series; CIRC/LCIRC keep their slash-year form.
      def normalize_ir_slash_year_to_update!
        return unless @cleaned =~ /\bIR\b/ && !@cleaned.include?("CIRC")

        @cleaned = @cleaned.gsub(%r{(\d)r(\d{1,2})/(\d{2,4})}) do
          num, mon, yr = ::Regexp.last_match(1), ::Regexp.last_match(2), ::Regexp.last_match(3)
          yyyy = yr.length == 2 ? "19#{yr}" : yr
          "#{num}/Upd1-#{yyyy}#{format('%02d', mon.to_i)}"
        end
      end

      # Uppercase lone letter suffixes attached to numbers. NCSTAR keeps
      # lowercase volume letters (e.g. "1-1av1") per its grammar.
      def normalize_letter_suffix_casing!
        uppercase_dash_letter!
        uppercase_trailing_letter!
        uppercase_revision_letter!
        uppercase_letter_before_revision!
        uppercase_letter_before_volume! unless @cleaned.include?("NCSTAR")
      end

      # Trailing "-a" → "-A" at end of identifier.
      def uppercase_dash_letter!
        @cleaned = @cleaned.gsub(/(\d)-([a-z])$/) { "#{$1}-#{$2.upcase}" }
      end

      # Trailing "a" → "A" when attached directly to a digit (excludes
      # "r" to preserve revision+year patterns like "73-197r").
      def uppercase_trailing_letter!
        @cleaned = @cleaned.gsub(/(\d)([a-z&&[^r]])$/) { "#{$1}#{$2.upcase}" }
      end

      # Letter suffix on revision: "22r1a" → "22r1A".
      def uppercase_revision_letter!
        @cleaned = @cleaned.gsub(/(\d)(r)(\d+)([a-z])$/) do
          "#{$1}#{$2}#{$3}#{$4.upcase}"
        end
      end

      # Letter between number and revision: "53ar1" → "53Ar1".
      def uppercase_letter_before_revision!
        @cleaned = @cleaned.gsub(/(\d)([a-z])(r\d)/) do
          "#{$1}#{$2.upcase}#{$3}"
        end
      end

      # Letter between number and volume: "1-2bv1" → "1-2Bv1". Skipped
      # for NCSTAR which preserves lowercase letters per its grammar.
      def uppercase_letter_before_volume!
        @cleaned = @cleaned.gsub(/(\d)([a-z&&[^r]])(v\d+)/) do
          "#{$1}#{$2.upcase}#{$3}"
        end
      end

      # Volume/draft spacing and supplement typo fixes that must run
      # before the more general draft and supplement normalizations.
      def normalize_draft_and_volume!
        @cleaned = @cleaned.gsub(/(\d{2}-\d{4})\s+(\d)$/, '\1 v\2')
        @cleaned = @cleaned.gsub(/(\d)-draft(\d)/, '\1 -draft \2')
        @cleaned = @cleaned.gsub(/(\d)draft(\d)/, '\1 -draft \2')
        @cleaned = @cleaned.gsub(/(\d)suprev/, '\1supprev')
        @cleaned = @cleaned.gsub(
          /(\d{2,})([A-Z])(r\d+)([-\s]draft\d*)/, '\1\2 \3\4'
        )
      end

      # Roman numeral volumes → "v<arabic> ver<version>" per NIST spec.
      def convert_roman_volumes!
        @cleaned = @cleaned.gsub(/(\d+)-([IVX]+)-(\d+(?:\.\d+)*)/) do
          "#{Regexp.last_match(1)} v#{roman_to_arabic(Regexp.last_match(2))} " \
            "ver#{Regexp.last_match(3)}"
        end
      end

      # LCIRC supplement with slash-year separator, and "Pt" part prefix
      # with revision.
      def normalize_supplement_and_part!
        @cleaned = @cleaned.gsub(/(\d)(supp\d+\/\d{4})/, '\1 \2')
        @cleaned = @cleaned.gsub(/(\d)Pt(\d+)(r\d+)/, '\1 pt\2 \3')
      end

      # Version notation: insert spaces between digits and "ver" / "v",
      # split combined fields, normalize volume ranges.
      def normalize_version_notation!
        @cleaned = @cleaned.gsub(/(\d)ver(\d)/, '\1 ver \2')
        @cleaned = @cleaned.gsub(/ver(\d+)e(\d{4})/, 'ver\1 e\2')
        @cleaned = @cleaned.gsub(/ver(\d+)v(\d+)/, 'ver\1 v\2')
        @cleaned = @cleaned.gsub(/(\d)(v\d+\.\d+)/, '\1 \2')
        @cleaned = @cleaned.gsub(/(\d)(v\d+\.\d+)/, '\1 \2')
        @cleaned = @cleaned.gsub(/(\d)(v\d+)\s+(\d+)$/, '\1 \2.\3')
        @cleaned = @cleaned.gsub(/(\d)(v\d+)\s+(\d+)\s+(\d+)$/, '\1 \2.\3.\4')
        @cleaned = @cleaned.gsub(/(\d)(v\d+[a-z]-[a-z])/, '\1 \2')
        @cleaned = @cleaned.gsub(/(\d)(v\d+[A-Z])/, '\1 \2')
        @cleaned = @cleaned.gsub(/(v\d+)([A-Z])-([A-Z])/, '\1\2-\3'.downcase)
      end

      # Edition year suffix shorthand: "2006ed." → "e2006".
      def normalize_edition_year_suffix!
        @cleaned = @cleaned.gsub(/(\d{4})ed\./, 'e\1')
      end

      # Revision attached to a number with optional letter suffix. When
      # a letter suffix is present, keep them together for the
      # second_number grammar rule; otherwise insert a space before
      # following uppercase letters or update keywords.
      def normalize_revision_with_letter!
        @cleaned = @cleaned.gsub(/(\d+)(r\d{1,2})([a-z])(?=-|[A-Z]|$)/) do
          "#{Regexp.last_match(1)}#{Regexp.last_match(2)}" \
            "#{Regexp.last_match(3).upcase}"
        end
        # rubocop:disable Layout/LineLength
        @cleaned = @cleaned.gsub(/(\d+)(r\d{1,2})(?![a-zA-Z])(?=[A-Z]|-(?=[A-Z])|\/(?:upd|errata|insert))/) do
          "#{Regexp.last_match(1)} #{Regexp.last_match(2)}"
        end
        # rubocop:enable Layout/LineLength
      end

      # Dotted versions with internal spaces ("v1 1" → "v1.1"). Negative
      # lookahead prevents swallowing draft stage digits ("189 2pd").
      def normalize_version_dotted_spaces!
        # rubocop:disable Layout/LineLength
        @cleaned = @cleaned.gsub(/(\b(?:v|\d)[v\d]*[-A-Z]*)\s+(\d+)(?!(?i:pd|wd|prd)\b)\s+(\d+)(?!(?i:pd|wd|prd)\b)/, '\1.\2.\3')
        @cleaned = @cleaned.gsub(/(\b(?:v|\d)[v\d]*)\s+(\d+)(?!(?i:pd|wd|prd)\b)/, '\1.\2')
        # rubocop:enable Layout/LineLength
      end

      # Update markers ("-upd", "/upd") need a space before them so the
      # grammar's update rule can match.
      def normalize_update_markers!
        @cleaned = @cleaned.gsub(/(\d+)-upd(\d*)/, '\1 -upd\2')
        @cleaned = @cleaned.gsub(/(\d+)\/upd(\d*)/, '\1 /upd\2')
        @cleaned = @cleaned.gsub(/([a-z]\d+)-upd/, '\1 -upd')
        @cleaned = @cleaned.gsub(/([a-z]\d+)\/upd/, '\1 /upd')
        @cleaned = @cleaned.gsub(/(\d+[A-Z])-upd(\d*)/, '\1 -upd\2')
        @cleaned = @cleaned.gsub(/(\d+[A-Z])\/upd(\d*)/, '\1 /upd\2')
      end

      # Supplement prefix variants ("sup", "sup+", "supp") all need a
      # space before them; the "sup" form is normalized to "supp" when
      # attached to a letter suffix or slash-year.
      def normalize_supplement_variants!
        @cleaned = @cleaned.gsub(/(\d)(sup\d)/, '\1 \2')
        @cleaned = @cleaned.gsub(/(\d)(sup+)(\d)/, '\1 \2\3')
        @cleaned = @cleaned.gsub(/(\d)(sup\+)(\d)/, '\1 \2\3')
        @cleaned = @cleaned.gsub(/(\d)(sup\d+)/, '\1 \2')
        @cleaned = @cleaned.gsub(/(\d)(sup\d+\b)/, '\1 \2')
        @cleaned = @cleaned.gsub(/(\d+[A-Z])sup(\b)/, '\1supp\2')
        @cleaned = @cleaned.gsub(/(\d+)sup(\d+\/\d{4})/, '\1supp\2')
        @cleaned = @cleaned.gsub(/(\d)(supp?)-(\d{4})(?![\d\/])/, '\1supp\3')
      end

      # Standalone "r" between number-letter and revision, bare trailing
      # "r" → "r1" (V1 empty-revision normalization), and revision
      # directly followed by a language code.
      def normalize_revision_language!
        @cleaned = @cleaned.gsub(/(\d[a-z])r\b/, '\1 r')
        @cleaned = @cleaned.gsub(/(\d)r\z/, '\1r1')
        @cleaned = @cleaned.gsub(
          /(r\d+)(es|pt|chi|viet|port|esp)\b/, '\1 \2'
        )
      end

      # MR-format translation codes (".spa", ".por", ".ind") would be
      # misparsed as letter suffixes — convert the trailing dot to a space.
      def normalize_mr_translation_codes!
        @cleaned = @cleaned.gsub(
          /^([A-Z]+)\.SP\.(\d+)\.([a-z]{2,4})$/, '\1.SP.\2 \3'
        )
        @cleaned = @cleaned.gsub(
          /^([A-Z]+)\.([A-Z]+)\.(\d+)\.([a-z]{2,4})$/, '\1.\2.\3 \4'
        )
      end

      # Trailing "-YYYY" → "eYYYY" edition marker, but only when the
      # four-digit group is plausibly a year (1901–2099). Part numbers
      # outside that range (e.g. SP 250-1039) are left untouched.
      #
      # The letter suffix may be lower- or uppercase (e.g. SP 800-38b-2005);
      # it is upcased so the year edition splits off cleanly and the letter
      # becomes a Part component ("800-38Be2005"), matching how a letter
      # suffix without a year (800-38a → 800-38A) is already normalized.
      # "e"/"E" are excluded from the letter so they cannot be confused with
      # the edition marker itself.
      def convert_dashyear_to_edition!
        @cleaned = @cleaned.gsub(
          /(?<!e\d)(?<![eE-])(\d(?:[A-DF-Za-df-z]?))-(\d{4})(?=\s|$)/,
        ) do |match|
          prefix = Regexp.last_match(1)
          year = Regexp.last_match(2).to_i
          year.between?(1901, 2099) ? "#{prefix.upcase}e#{year}" : match
        end
      end

      # Series-specific reverts: HB handbooks, OWMWP dates, and RPT year
      # ranges use dash-year structurally (not as an edition marker), so
      # the broad convert_dashyear_to_edition! rule would corrupt them.
      def revert_dashyear_for_series!
        revert_handbook_edition!
        revert_owmwp_date!
        revert_report_year_range!
        revert_circ_supplement_year_range!
      end

      # CIRC/LCIRC year-only series supplements: "NBS CIRC sup1925-1926" is a
      # supplement spanning a year range, so the trailing "-1926" is a range
      # end, not an edition. convert_dashyear_to_edition! would have rewritten
      # it to "sup1925e1926"; restore the dash so the circ_supplement_identifier
      # grammar can read the range (pubid/pubid#152).
      def revert_circ_supplement_year_range!
        return unless @cleaned.include?("CIRC")

        # Anchor on the series prefix ("CIRC " / "CIRC." / "LCIRC ") so only the
        # whole-series form (sup right after the series, no base number) is
        # reverted — a based "24sup1940e1950" keeps its genuine edition.
        @cleaned = @cleaned.gsub(/(CIRC[ .])(supp?)(\d{4})e(\d{4})(?=\s|$)/, '\1\2\3-\4')
      end

      # HB handbooks: "HB 130e1979" → "HB 130-1979" (year is part of
      # the handbook designation, not an edition marker).
      def revert_handbook_edition!
        @cleaned = @cleaned.gsub(
          /\b(HB|HB\s+)[^:\s.]*?(\d+)e(\d{4})(?=\s|$)/, '\1\2-\3'
        )
      end

      # OWMWP series: dates use MM-DD-YYYY format, so "OWMWP 06-13e2018"
      # reverts to "OWMWP 06-13-2018".
      def revert_owmwp_date!
        @cleaned = @cleaned.gsub(
          /\b(OWMWP|OWMWP\s*)[^:\s]*?(\d{2})-(\d{2})e(\d{4})(?=\s|$)/,
          '\1\2-\3-\4',
        )
      end

      # RPT series: year ranges "1946-1947" should not be reinterpreted as
      # editions. Only revert when the first year precedes the second.
      def revert_report_year_range!
        @cleaned = @cleaned.gsub(
          /\b(RPT|RPT\s*)([^:\s]*?)(\d{4})e(\d{4})(?=\s|$)/,
        ) { |m| build_report_year_range(m, Regexp.last_match.captures) }
      end

      # Build the reverted year-range form from the gsub captures, or
      # return the original match when the years are not a forward range.
      def build_report_year_range(match, captures)
        prefix, separator, first, second = captures
        return match unless first.to_i < second.to_i

        "#{prefix}#{separator}#{first}-#{second}"
      end

      # Verbose version markers ("v1.1" → "ver1.1", "Ver. 2.0" →
      # "ver2.0"), MR-format "-v" → ".ver".
      def normalize_version_verbose!
        @cleaned = @cleaned.gsub(/-v(\d+\.\d+)/, '.ver\1')
        @cleaned = @cleaned.gsub(/\bVer\.\s+(\d+(?:\.\d+)*)/, 'ver\1')
        @cleaned = @cleaned.gsub(/\bv(\d+\.\d+(?:\.\d+)*)/, 'ver\1')
      end

      # Part notation: uppercase "P" → "p"; lone "p"/"n" → "pt" (unless
      # followed by a 4-digit year, which is part+year not part-prefix).
      def normalize_part_notation!
        @cleaned = @cleaned.gsub(/(\d)P(\d)/, '\1 p\2')
        @cleaned = @cleaned.gsub(/\b([pn])(\d+)(?!\d{4}\b)/, 'pt\2')
        @cleaned = @cleaned.gsub(/(\d)([pP]\d+)/, '\1 \2')
      end

      # Series-specific spacing rules: CRPL-F needs a space after the
      # letter band; compound report numbers ("17-917v3") need the
      # volume broken out.
      def normalize_series_specific_spacing!
        @cleaned = @cleaned.gsub(/(NBS CRPL-F-[AB])(\d)/, '\1 \2')
        @cleaned = @cleaned.gsub(/(CRPL-F-[AB])(\d)/, '\1 \2')
        @cleaned = @cleaned.gsub(/(\d+-\d+)(v\d+)(?![.\d])/, '\1 \2')
      end

      # Verbose keyword spellings ("Version", "Revision", "Part", "Add",
      # "Suppl", "report") normalized to their short canonical forms.
      def normalize_verbose_keywords!
        @cleaned = @cleaned.gsub(/(\d+)\s+Suppl\b/, '\1Suppl')
        @cleaned = @cleaned.gsub(/\s+Version\s+(\d+)/, ' ver \1')
        @cleaned = @cleaned.gsub(/\s+Revision\s+\(r\)/, " r")
        @cleaned = @cleaned.gsub(/\s+Part\s+(\d+)/, 'pt\1')
        @cleaned = @cleaned.gsub(/(\d[a-z]?)\s+Add\b\.?/i) do
          "#{Regexp.last_match(1).upcase} Add."
        end
        @cleaned = @cleaned.gsub(/(\d+)\s+rev\s+(\d{4})/, '\1r\2')
        @cleaned = @cleaned.gsub(/\breport\s*;\s*/, "RPT ")
        @cleaned = @cleaned.gsub(/\breport\b/, "RPT")
      end

      # Translate a Roman numeral into its Arabic equivalent.
      def roman_to_arabic(roman)
        ROMAN_TO_ARABIC.fetch(roman, roman)
      end
    end
  end
end
