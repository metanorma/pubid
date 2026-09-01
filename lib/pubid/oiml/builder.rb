# frozen_string_literal: true

module Pubid
  module Oiml
    class Builder
      # Type to identifier class mapping (MECE)
      TYPE_CLASS_MAP = {
        "B" => "BasicPublication",
        "Bulletin" => "Bulletin",
        "D" => "Document",
        "E" => "ExpertReport",
        "G" => "Guide",
        "R" => "Recommendation",
        "S" => "SeminarReport",
        "V" => "Vocabulary",
      }.freeze

      def build(parsed_hash)
        # Check for short amendment format (has amd_marker)
        if parsed_hash[:amd_marker]
          return build_short_amendment(parsed_hash)
        end

        # Check for supplements first (have base)
        if parsed_hash[:base]
          return build_supplement(parsed_hash)
        end

        # Build base document
        build_base_document(parsed_hash)
      end

      private

      def build_short_amendment(parsed_hash)
        # Build base identifier from the code and type
        base_hash = {
          publisher: parsed_hash[:publisher],
          type: parsed_hash[:type],
        }

        # Copy number/part/subpart from base_code
        if parsed_hash[:base_code]
          base_hash[:number] = parsed_hash[:base_code][:number]
          if parsed_hash[:base_code][:part]
            base_hash[:part] =
              parsed_hash[:base_code][:part]
          end
          if parsed_hash[:base_code][:subpart]
            base_hash[:subpart] =
              parsed_hash[:base_code][:subpart]
          end
        end

        # Build the base document
        base = build_base_document(base_hash)

        # Create amendment
        amendment = Identifiers::Amendment.new
        amendment.base = base

        # Extract year from edition_format if present, otherwise from year directly
        year_value = if parsed_hash[:edition_format].is_a?(Hash)
                       parsed_hash[:edition_format][:year]
                     else
                       parsed_hash[:year]
                     end

        amendment.year = year_value.to_s if year_value
        amendment.language = extract_language(parsed_hash[:language]) if parsed_hash[:language]

        # Track if amendment itself was parsed with Edition format
        if parsed_hash[:edition_format]
          amendment.parsed_format = "long"
        end

        amendment
      end

      def build_supplement(parsed_hash)
        marker = parsed_hash[:trailing_marker].to_s if parsed_hash[:trailing_marker]
        plus_marker = parsed_hash[:plus_marker].to_s if parsed_hash[:plus_marker]

        # Determine supplement type. The trailing word ("Amendment"/"Errata")
        # selects the class; the concrete class then carries the word via
        # #supplement_type, so only the `trailing` flag needs storing.
        supplement_class = if parsed_hash[:annex_letter] || parsed_hash[:annex_marker]
                             Identifiers::Annex
                           elsif marker == "Errata" || plus_marker == "Errata"
                             Identifiers::Errata
                           else
                             Identifiers::Amendment
                           end

        supplement = supplement_class.new
        supplement.trailing = true if marker
        supplement.joined = true if plus_marker

        # Recursively parse base identifier
        if parsed_hash[:base]
          supplement.base = build(parsed_hash[:base])
        end

        # Extract year from edition_format if present, otherwise from year directly
        year_value = if parsed_hash[:edition_format].is_a?(Hash)
                       parsed_hash[:edition_format][:year]
                     else
                       parsed_hash[:year]
                     end

        # Set supplement-specific attributes
        supplement.year = year_value.to_s if year_value
        supplement.language = extract_language(parsed_hash[:language]) if parsed_hash[:language]
        supplement.letter = parsed_hash[:annex_letter].to_s if parsed_hash[:annex_letter]

        # Annex with no year of its own but a dated base ("R 60:2017 Annexes"):
        # the year belongs to the base and must render glued to it.
        if supplement.is_a?(Identifiers::Annex) && !year_value &&
            supplement.base&.date
          supplement.year_on_base = true
        end

        # Track if supplement itself was parsed with Edition format
        if parsed_hash[:edition_format]
          supplement.parsed_format = "long"
        end

        supplement
      end

      def build_base_document(parsed_hash)
        # Determine identifier class from type
        type = parsed_hash[:type].to_s
        class_name = TYPE_CLASS_MAP[type] || "Recommendation" # Default to R
        identifier_class = Identifiers.const_get(class_name)

        identifier = identifier_class.new

        # Handle code (number-part-subpart-suffix) specially
        if parsed_hash[:number] || parsed_hash[:part] || parsed_hash[:subpart] || parsed_hash[:code_suffix]
          code_attrs = {}
          if parsed_hash[:number]
            code_attrs[:number] =
              parsed_hash[:number].to_s
          end
          code_attrs[:part] = parsed_hash[:part].to_s if parsed_hash[:part]
          if parsed_hash[:subpart]
            code_attrs[:subpart] =
              parsed_hash[:subpart].to_s
          end
          if parsed_hash[:code_suffix]
            code_attrs[:suffix] = parsed_hash[:code_suffix].to_s
            code_attrs[:space_suffix] = true if parsed_hash.key?(:space_suffix)
          end
          # The code fields are flat index columns on the leaf (see
          # Identifiers::CodeNumber) — `number` is what relaton-index keys on —
          # so they are assigned individually rather than as a Code object.
          # Bulletin has no code columns and never reaches this branch.
          code_attrs.each { |name, value| identifier.public_send(:"#{name}=", value) }
        end

        # Handle other attributes
        identifier.publisher = parsed_hash[:publisher].to_s if parsed_hash[:publisher]

        # Handle edition attribute
        identifier.edition = parsed_hash[:edition].to_s if parsed_hash[:edition]

        # Handle year -> date conversion
        # Year could be in edition_format hash or directly
        year_value = nil
        if parsed_hash[:edition_format].is_a?(Hash)
          year_value = parsed_hash[:edition_format][:year]
          # Also extract edition if present
          identifier.edition = parsed_hash[:edition_format][:edition].to_s if parsed_hash[:edition_format][:edition]
        elsif parsed_hash[:year]
          year_value = parsed_hash[:year]
        end

        if year_value
          identifier.date = Pubid::Components::Date.new(year: year_value.to_s)
        end

        # Bulletin-specific locator fields. The structured form captures
        # issue/sequence directly; the citation form captures volume/issue/
        # article_id, which we decode to the same (year, issue, sequence)
        # tuple. Year comes from either the date rule (structured) or the
        # article_id (citation).
        if identifier.is_a?(Identifiers::Bulletin)
          apply_bulletin_locator(identifier, parsed_hash)
        end

        # Determine parsed format for round-trip fidelity
        # If edition_format was captured, it means "Edition" text was present
        identifier.parsed_format = if parsed_hash[:edition_format]
                                     "long"
                                   elsif parsed_hash[:space_before_lang]
                                     "short_with_space"
                                   elsif parsed_hash[:article_id]
                                     # Bulletin citation form — preserve on
                                     # the identifier so default to_s gives
                                     # back the citation string verbatim.
                                     "citation"
                                   else
                                     "short"
                                   end

        # Handle stage attributes
        identifier.stage = parsed_hash[:stage].to_s if parsed_hash[:stage]
        identifier.iteration = parsed_hash[:iteration].to_s if parsed_hash[:iteration]

        # Handle language
        identifier.language = extract_language(parsed_hash[:language]) if parsed_hash[:language]

        identifier
      end

      # Populate issue/sequence on a Bulletin from either parse shape.
      # Structured: :issue and :sequence captured directly as zero-padded
      # strings. Citation: :volume_roman, :issue_arabic, :article_id —
      # decode the 8-digit article_id to recover year+issue+sequence.
      #
      # For the citation form, the parsed roman volume is cross-checked
      # against the year decoded from the article_id; a mismatch warns but
      # does not raise (the article_id is the source of truth — the roman
      # volume is redundant display).
      def apply_bulletin_locator(identifier, parsed_hash)
        if parsed_hash[:article_id]
          article_id = parsed_hash[:article_id].to_s
          identifier.date ||= Pubid::Components::Date.new
          identifier.date.year = article_id[0, 4]
          identifier.issue = article_id[4, 2]
          identifier.sequence = article_id[6, 2]
          warn_on_volume_mismatch(identifier, parsed_hash[:volume_roman])
          return
        end

        identifier.issue = parsed_hash[:issue].to_s if parsed_hash[:issue]
        identifier.sequence = parsed_hash[:sequence].to_s if parsed_hash[:sequence]
      end

      # Citation form carries the volume in two places: spelled out as a
      # roman numeral ("LXVII") and encoded in the 8-digit article_id
      # (year+issue+sequence, where year - 1959 = volume). They should
      # agree; if they don't, the input was malformed. Warn loudly so the
      # user sees the discrepancy, but continue using the article_id
      # (deterministic) rather than the roman (possibly mistyped).
      def warn_on_volume_mismatch(identifier, parsed_volume_roman)
        return unless parsed_volume_roman && identifier.date&.year

        declared = parsed_volume_roman.to_s
        computed = Identifiers::Bulletin.to_roman(identifier.date.year.to_i -
                                                  Identifiers::Bulletin::BASE_YEAR_OFFSET)
        return if declared == computed

        warn "OIML Bulletin citation volume mismatch: parsed '#{declared}' " \
             "but article_id year #{identifier.date.year} implies '#{computed}'"
      end

      def extract_language(lang_data)
        # Handle both direct string and nested hash from parser
        case lang_data
        when Hash
          lang_data[:language].to_s
        else
          lang_data.to_s
        end
      end
    end
  end
end
