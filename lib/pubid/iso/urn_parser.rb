# frozen_string_literal: true

module Pubid
  module Iso
    # Parses RFC 5141-bis compliant URNs into ISO identifiers
    #
    # URN format: urn:iso:std:{publisher}:{type}:{number}[-{part}]:{year}:{supplements}
    #
    # Examples:
    # - urn:iso:std:iso:9001:2019
    # - urn:iso:std:iso:tr:9001:2019
    # - urn:iso:std:iso:9001:2019:stage-40.00
    # - urn:iso:std:iso:9001:2019:amd:1:2020
    # - urn:iso:std:iso-iec:27001:2013
    class UrnParser
      # Reverse mappings from URN format to PubID components
      TYPED_STAGE_REVERSE_MAP = {
        "WD" => :wd,
        "WDS" => :wds,
        "CD" => :cd,
        "CDV" => :cdv,
        "DIS" => :dis,
        "FDIS" => :fdis,
        "PDAM" => :pdam,
        "DAM" => :dam,
        "FDAM" => :fdamd,
        "DCOR" => :dcor,
        "FDCOR" => :fdcor,
        "CDTS" => :cdts,
        "DTS" => :dts,
        "FDTS" => :fdts,
      }.freeze

      SUPPLEMENT_TYPE_MAP = {
        "amd" => :amd,
        "cor" => :cor,
        "sup" => :sup,
        "add" => :add,
      }.freeze

      TYPE_CODE_REVERSE_MAP = {
        "tr" => :tr,
        "ts" => :ts,
        "pas" => :pas,
        "guide" => :guide,
        "dir" => :dir,
        "dir-sup" => :dir_sup,
        "iwa-sup" => :iwa_sup,
        "isp" => :isp,
        "iwa" => :iwa,
        "r" => :r,
        "data" => :data,
      }.freeze

      # Parse ISO URN string
      # @param urn [String] URN string to parse
      # @return [Identifier] parsed identifier
      def self.parse(urn)
        new.parse_urn(urn)
      end

      # Parse URN string into identifier
      # @param urn [String] URN string
      # @return [Identifier] parsed identifier
      def parse_urn(urn)
        # Remove urn:iso:std: prefix
        unless urn.start_with?("urn:iso:std:")
          raise ArgumentError,
                "Invalid ISO URN: #{urn}"
        end

        parts = urn.sub("urn:iso:std:", "").split(":")

        # Series suffix: a trailing "ser" marks an all-parts identifier. Strip
        # it before component parsing so it is not misread as a language or
        # supplement token (which previously rendered as "(SER)").
        all_parts = false
        if parts.last == "ser"
          parts.pop
          all_parts = true
        end

        # Parse publisher(s) - first part
        publishers = parse_publisher(parts.shift)

        # Parse type - optional (defaults to IS)
        type_code = nil
        type_code = parse_type(parts.first) if parts.first && TYPE_CODE_REVERSE_MAP.key?(parts.first.downcase)
        parts.shift if type_code

        # Parse number
        number_part = parts.shift
        number, part, subpart = parse_number_part(number_part)

        # Parse year if present (4-digit year)
        year = nil
        if parts.first&.match(/^\d{4}$/)
          year = parts.shift
        end

        # Handle URN-style part notation (:-22, :-5-1-1, etc.)
        # These can come before or after year/edition in URN format
        # Note: The parts are split by ':', so :-22 becomes two parts: "10164" and "-22"
        if parts.first&.start_with?("-")
          part_str = parts.shift
          # Re-parse the number part with the URN-style part
          number, part, subpart = parse_number_part("#{number}#{part_str}")
        end

        # Parse year if present (4-digit year) - may come after part
        if year.nil? && parts.first&.match(/^\d{4}$/)
          year = parts.shift
        end

        # Parse edition if present (ed-N format) - comes after year in URN
        edition = nil
        if parts.first&.start_with?("ed-")
          edition = parts.shift.sub("ed-", "").to_i
        end

        # Parse language if present (2-letter codes like "en" or comma-separated)
        languages = nil
        if parts.first && !parts.first.match(/^\d+$/) &&
            !parts.first.match?(/^(amd|cor|sup|add|v\d+|stage-|ed-)/i) &&
            !TYPED_STAGE_REVERSE_MAP.key?(parts.first.upcase) &&
            !parts.first.match?(/^[A-Z]+\.\d+$/i)
          languages = parse_languages(parts.shift)
        end

        # Check for stage (stage-XX.XX or typed stage like WD, CD, etc.)
        # IMPORTANT: This must come AFTER edition/part/language parsing but BEFORE supplements parsing
        stage_code = nil
        stage_iteration = nil
        harmonized_stage_code = nil # Track full harmonized code for lookup
        stage_from_abbr = nil # Track stage code from typed abbreviation
        if parts.first&.start_with?("stage-")
          stage_str = parts.shift
          stage_code, stage_iteration = parse_stage_code(stage_str)
          # Set harmonized_stage_code AFTER parse_stage_code has stripped .vX suffix
          harmonized_stage_code = stage_str.sub("stage-", "").sub(/\.v\d+$/i,
                                                                  "")
        elsif TYPED_STAGE_REVERSE_MAP.key?(parts.first&.upcase) ||
            (parts.first&.match?(/^[A-Za-z]+\.\d+$/) &&
             TYPED_STAGE_REVERSE_MAP.key?(parts.first.upcase.split(".").first))
          stage_abbr = parts.first.upcase
          # The family comes from the abbreviation without its iteration
          # ("FDAM.3" is still the amd family).
          family = Pubid::Iso.locate_stage(stage_abbr.split(".").first)&.type_code&.to_s
          # A supplement-family stage directly before its own supplement
          # type token ("...:FDAM:amd:1:v1") names the SUPPLEMENT's stage:
          # consuming it as the base's stage builds the base as a base-less
          # supplement, which cannot render.
          supplement_follows =
            %w[amd cor suppl add].include?(family) &&
            parts.drop(1).any? do |token|
              family == SUPPLEMENT_TYPE_MAP[token.to_s.downcase]&.to_s
            end
          unless supplement_follows
            parts.shift
            # Check for iteration (WD.2 format)
            if stage_abbr.include?(".")
              abbr_part, iteration_part = stage_abbr.split(".")
              stage_code = TYPED_STAGE_REVERSE_MAP[abbr_part]
              stage_from_abbr = stage_code
              stage_iteration = iteration_part.to_i
            else
              stage_code = TYPED_STAGE_REVERSE_MAP[stage_abbr]
              stage_from_abbr = stage_code
            end
          end
        end

        # Check for supplements (amd, cor, sup, add)
        supplements = []
        while parts.any?
          supp_type = nil
          supp_number = nil
          supp_version = nil
          supp_year = nil
          supp_stage = nil

          # Check for supplement stage
          if parts.first&.start_with?("stage-")
            supp_stage_data = parts.shift
            supp_stage, = parse_stage_code(supp_stage_data)
          elsif TYPED_STAGE_REVERSE_MAP.key?(parts.first&.upcase)
            supp_stage_abbr = parts.shift.upcase
            supp_stage = TYPED_STAGE_REVERSE_MAP[supp_stage_abbr]
          end

          # Check for supplement type (amd, cor, sup, add)
          if SUPPLEMENT_TYPE_MAP.key?(parts.first&.downcase)
            supp_type = SUPPLEMENT_TYPE_MAP[parts.shift.downcase]
          end

          # Check for year or supplement number
          if parts.first&.match(/^\d+$/)
            if parts.first&.match(/^\d{4}$/)
              # 4 digits = year
              supp_year = parts.shift
            else
              # 1-3 digits = supplement number
              supp_number = parts.shift.to_i
            end
          end

          # Check for version (v1, v2, etc.) after year or number.
          # Legacy year-overloaded wire ("amd:2007:v2" -- the number rode
          # the version slot): a v-token with no preceding number carries
          # the NUMBER. The RFC 5141 additive extension ("amd:1:2007:v2")
          # keeps the number in its own slot, so a v-token after a number
          # is the true <supplversion>.
          if parts.first&.start_with?("v")
            version_str = parts.shift.sub("v", "")
            value = version_str.split(".").first.to_i
            if supp_number.nil?
              supp_number = value
            else
              supp_version = value
            end
          end

          # Next part might be year if not already set
          if supp_year.nil? && parts.first&.match(/^\d{4}$/)
            supp_year = parts.shift
          end

          # A v-token after the year ("amd:1:2007:v1") would otherwise be
          # left for the next loop iteration, wrapping a type-less
          # supplement around the real one and losing the base.
          if parts.first&.start_with?("v")
            version_str = parts.shift.sub("v", "")
            value = version_str.split(".").first.to_i
            if supp_number.nil?
              supp_number = value
            else
              supp_version = value
            end
          end

          # Check for language after supplement
          supp_languages = nil
          if parts.first && !parts.first.match(/^\d+$/) && !parts.first.match?(/^(amd|cor|sup|add|v\d+|stage-)/i)
            supp_languages = parse_languages(parts.shift)
          end

          supplements << {
            type: supp_type,
            number: supp_number,
            version: supp_version,
            year: supp_year,
            stage: supp_stage,
            languages: supp_languages,
          }
        end

        # Build the identifier hash
        build_identifier(publishers, number, part, subpart, type_code, stage_code, stage_iteration,
                         harmonized_stage_code, stage_from_abbr, year, edition, languages, supplements,
                         all_parts)
      end

      private

      # Helper to find IS-type TypedStage by harmonized stage code
      # Used when URN doesn't specify a type code (defaults to IS)
      # Prefers the most specific (non-published) stage
      def scheme_is_typed_stage_by_harmonized(harmonized_code)
        candidates = Pubid::Iso.all_typed_stages.select do |ts|
          ts.type_code.to_s == "is" && ts.harmonized_stages&.include?(harmonized_code)
        end

        return nil if candidates.empty?

        # Prefer non-published stages (stage_code != "published")
        # This ensures PRF is preferred over published IS for 60.00
        non_published = candidates.reject do |ts|
          ts.stage_code.to_s == "published"
        end
        candidates = non_published unless non_published.empty?

        # Among remaining candidates, prefer the stage with MORE harmonized codes (more general)
        # WD covers 6 codes, WDS covers only 2 — WD should be preferred for shared codes
        candidates.max_by { |ts| ts.harmonized_stages&.length || 0 }
      end

      # Parse publisher component (iso, iso-iec, etc.)
      def parse_publisher(publisher_str)
        publisher_str.split("-").map(&:upcase)
      end

      # Parse type component
      def parse_type(type_str)
        TYPE_CODE_REVERSE_MAP[type_str.downcase]
      end

      # Parse number component (number, part, subpart)
      # URN format uses :- prefix for parts: 10164:-22 or 10164:-5-1-1
      def parse_number_part(number_str)
        return [nil, nil, nil] unless number_str

        # Check for URN-style part notation (:-22)
        if number_str.match?(/^\w+:-/)
          # Split by :- to get number and parts
          main_and_parts = number_str.split(":-")
          number = main_and_parts[0]

          # The rest are parts/subparts separated by -
          parts = main_and_parts[1..].join("-").split("-") if main_and_parts.length > 1
          part = parts[0] if parts && parts[0]
          # Join all remaining elements for subpart (e.g., "1-1" from ["5", "1", "1"])
          subpart = parts[1..].join("-") if parts && parts.length > 1
          [number, part, subpart]
        elsif number_str.include?("-")
          parts = number_str.split("-")
          number = parts[0]
          part = parts[1] if parts[1]
          subpart = parts[2..].join("-") if parts && parts.length > 2
          [number, part, subpart]
        else
          [number_str, nil, nil]
        end
      end

      # Parse stage code (stage-XX.XX format)
      # URN format may include iteration suffix: stage-30.00.v2
      # Returns: [harmonized_stage_code_symbol, iteration_number]
      # Note: The first value is the harmonized stage code (e.g., "30.00"), not a stage_code symbol
      def parse_stage_code(stage_str)
        stage_code = stage_str.sub("stage-", "")

        # Check for iteration suffix (.v2, .v3, etc.)
        if stage_code =~ /\.v(\d+)$/i
          iteration = Regexp.last_match(1).to_i
          stage_code = stage_code.sub(/\.v\d+$/i, "")
          [stage_code.to_sym, iteration]
        else
          # Return harmonized stage code as symbol, no iteration
          [stage_code.to_sym, nil]
        end
      end

      # Parse language component
      def parse_languages(lang_str)
        lang_str.split(",").map(&:upcase)
      end

      # Build identifier from parsed components
      def build_identifier(publishers, number, part, subpart, type_code, stage_code, stage_iteration,
                         harmonized_stage_code, stage_from_abbr, year, edition, languages, supplements,
                         all_parts = false)
        # Start with base document hash
        base_hash = {
          publisher: publishers.first,
          copublishers: publishers[1..]&.map { |c| { copublisher: c } },
        }

        # Build number_with_part (expected by Builder)
        if part || subpart
          number_with_part = number
          number_with_part += "-#{part}" if part
          number_with_part += "-#{subpart}" if subpart
          base_hash[:number_with_part] = number_with_part
        else
          base_hash[:number] = number
        end

        base_hash[:year] = year if year
        base_hash[:edition] = edition if edition

        # Add type_with_stage if type_code is present
        if type_code && type_code != :is
          base_hash[:type_with_stage] = type_code.to_s.upcase
          # Pin the document class to the explicit URN type token. The stage
          # block below may overwrite :type_with_stage with the stage's abbr
          # (e.g. "WDA" for 90.93, which only exists as an IS-typed stage), so
          # the builder needs this hint to keep e.g. TR a TechnicalReport.
          base_hash[:document_type] = type_code.to_s.upcase
        end

        # Add stage if present
        if stage_code
          typed_stage = nil

          if stage_from_abbr
            # Stage came from a typed abbreviation (e.g., WDS, DIS, CD)
            # Look up by abbreviation directly for exact match
            # The stage_from_abbr is the value from TYPED_STAGE_REVERSE_MAP
            # We need to find the reverse to get the original abbreviation
            abbr_str = TYPED_STAGE_REVERSE_MAP.key(stage_from_abbr)
            typed_stage = Pubid::Iso.locate_stage(abbr_str) if abbr_str
            # If no exact match, fall back to stage_code lookup
            typed_stage ||= Pubid::Iso.locate_stage_by_stage_code(stage_from_abbr)
          else
            # Stage came from a harmonized code (e.g., stage-20.20)
            # Look up by harmonized stage code
            # When no type_code is specified (default IS), look for IS type first
            if !type_code || type_code == :is
              typed_stage = scheme_is_typed_stage_by_harmonized(stage_code.to_s)
            end

            # Fall back to any typed stage if IS not found or type_code is specified
            typed_stage ||= Pubid::Iso.locate_stage_by_harmonized_code(stage_code.to_s)

            # Special handling for stage "40.00": prefer DIS over FCD when parsing from URN
            # This is because FCD is a legacy stage that maps to DIS in URN format
            if stage_code.to_s == "40.00" && typed_stage && typed_stage.stage_code.to_s == "fcd"
              dis_stage = Pubid::Iso.all_typed_stages.detect do |ts|
                ts.stage_code.to_s == "dis" && ts.harmonized_stages&.include?("40.00")
              end
              typed_stage = dis_stage if dis_stage
            end
          end

          if typed_stage
            base_hash[:type_with_stage] =
              typed_stage.abbr.is_a?(Array) ? typed_stage.abbr.first : typed_stage.abbr
          else
            # Fallback: use raw harmonized stage code (shouldn't happen if data is correct)
            base_hash[:stage] = harmonized_stage_code || stage_code.to_s
          end

          # Add stage iteration if present
          base_hash[:stage_iteration] = stage_iteration.to_s if stage_iteration
        end

        # Add languages if present
        if languages
          base_hash[:languages] = languages.join("/")
        end

        # Build supplements recursively (forward order: first supplement wraps base,
        # second wraps first, etc. -- matching URN left-to-right semantics)
        supplements.each do |supp|
          # A bare language token with no supplement identity names the BASE
          # document: wrapping it would build a supplement with no type,
          # number or base attribute, and a plain standard drops its base —
          # the whole document was lost, rendering "ISO (FR)".
          if supp[:type].nil? && supp[:stage].nil? && supp[:number].nil? &&
              supp[:year].nil? && supp[:languages]
            base_hash[:languages] = supp[:languages].join("/")
            next
          end

          supp_hash = {}

          if supp[:stage]
            # A harmonized code resolves through the deliverable type
            # (like the base stage); a supplement-family abbreviation
            # resolves by abbr -- the typed-stage code differs from the
            # abbr ("fdamd" for FDAM), so the stage-code lookup misses.
            typed_stage =
              if supp[:stage].to_s.match?(/\A\d\d\.\d\d\z/)
                # resolve within the supplement's own type family -- the
                # umbrella lookup prefers the IS family, which would turn
                # a staged Corrigendum into a plain IS
                code_str = supp[:stage].to_s
                type_str = supp[:type]&.to_s
                candidates = Pubid::Iso.all_typed_stages
                  .select { |st| st.harmonized_stages&.include?(code_str) }
                candidates.find { |st| st.type_code.to_s == type_str } ||
                  candidates.find { |st| st.type_code.to_s == "is" } ||
                  candidates.first
              else
                Pubid::Iso.locate_stage(supp[:stage].to_s.upcase) ||
                  Pubid::Iso.locate_stage_by_stage_code(supp[:stage])
              end
            supp_hash[:type_with_stage] = if
typed_stage
                                            typed_stage.abbr.is_a?(Array) ? typed_stage.abbr.first : typed_stage.abbr
                                          else
                                            supp[:type]&.to_s&.upcase
                                          end
          end

          supp_hash[:type_with_stage] ||= supp[:type].to_s.upcase if supp[:type]

          if supp[:number]
            supp_hash[:number] = supp[:number].to_s
          end

          if supp[:year]
            supp_hash[:year] = supp[:year].to_s
          end

          if supp[:version]
            supp_hash[:supplement_version] = supp[:version].to_s
          end

          if supp[:languages]
            supp_hash[:languages] = supp[:languages].join("/")
          end

          # Wrap current identifier with supplement
          base_hash = {
            base: base_hash,
            **supp_hash,
          }
        end

        # all_parts belongs on the outermost identifier (after any supplement wrapping)
        base_hash[:all_parts] = true if all_parts

        # Build the final identifier
        builder = Pubid::Iso::Builder.new
        builder.build(base_hash)
      end
    end
  end
end
