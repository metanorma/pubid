# frozen_string_literal: true

module Pubid
  module Nist
    module Identifiers
      # NIST Federal Information Processing Standards (FIPS)
      # Examples:
      # - "FIPS 140-3" (no NIST prefix)
      # - "NIST FIPS 140-3" (also accepted, normalizes to FIPS 140-3)
      class FederalInformationProcessingStandards < Identifier
        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            abbr: ["FIPS", "NIST FIPS"],
            stage_code: "published",
            type_code: "fips",
          ),
        ].freeze

        class << self
          def typed_stages
            TYPED_STAGES
          end

          def type
            { key: :fips,
            web: :federal_information_processing_standards, title: "Federal Information Processing Standards",
              short: "FIPS" }
          end
        end

        def series_code
          "FIPS"
        end

        # FIPS identifiers default to no publisher prefix
        def default_publisher
          ""
        end

        # Override to_mr_style so FIPS adds no default "NIST" prefix
        def to_mr_style
          # "NIST.FIPS.197" keeps a parsed publisher (the DOI suffix NIST
          # publishes); "FIPS.46e1977" has none and invents none.
          # Note: edition is appended directly to number without dot for FIPS
          result = [publisher, series_code].compact.join(".")
          result += ".#{number}" if number

          # FIPS uses dash notation for parts; render here and skip the generic
          # part rendering in the shared tail (which appends volume, edition,
          # supplement, version, update, etc.).
          result += "-#{part.value}" if part.is_a?(Components::Part)
          result += parts.map { |p| "-#{p}" }.join if parts&.any?

          result += append_mr_components(skip_part: true)

          result
        end

        public

        def to_short_style
          # FIPS format: "FIPS 14e1971" or "NIST FIPS 140-3" (preserve publisher if set)
          result = publisher ? "#{publisher} " : ""
          result += series_code

          if number
            # Convert dash-year patterns to edition format for FIPS
            # Pattern: "14-1971" → "14e1971" (edition year format)
            # But preserve dash for parts: "140-3" stays as-is
            if number =~ /^(\d{1,3})-(\d{4})$/
              # This is a number-year pattern (e.g., "14-1971")
              # Convert to edition format: "14e1971"
              number_part = $1
              year_part = $2
              result += " #{number_part}e#{year_part}"
            else
              result += " #{number}"
            end
          end

          # FIPS uses dash notation for parts: -1, -2, -3 (not pt1, pt2, pt3),
          # so render the part here and skip the generic part rendering in the
          # shared tail. The tail still appends volume, edition, version,
          # supplement, update, etc. — components FIPS previously dropped.
          if part.is_a?(Components::Part)
            result += "-#{part.value}"
          end

          result += append_short_components(skip_part: true)

          result
        end
      end
    end
  end
end
