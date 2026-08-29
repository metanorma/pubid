# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Csa
    module Identifiers
      # Combined represents CSA identifiers joined with "/" or ", "
      # Examples:
      #   CSA A23.1:24/CSA A23.2:24
      #   CSA N285.0:23/CSA N285.6 SERIES:23
      #   CSA A123.1-05/A123.5-05 (R2015)
      #   CSA B44:19/B44.1:19/B44.2:19 (triple combined)
      class Combined < Identifier
        # The co-equal designations, in printed order.
        #
        # One polymorphic collection, the IEC ConsolidatedIdentifier shape —
        # not the historical first/second/third triple, which hard-capped the
        # form at three and froze a non-standard hash shape. The first member
        # is the primary designation, which is what #root walks so the index
        # key is non-empty. Typed cross-flavor for the same reason as
        # WrapperIdentifier#base.
        attribute :identifiers, ::Pubid::Identifier, polymorphic: true,
                                                     collection: true
        attribute :reaffirmation, :string
        attribute :original_reaffirmation_4digit, :boolean, default: -> {
          false
        }
        attribute :package, :string
        attribute :year_format, :string # Dummy for compatibility
        attribute :separator, :string, default: -> { "/" } # "/" or ", "

        # A combined id stores its members in `identifiers`, not `base`, so
        # walk the primary designation to the origin document
        # (Iec::Identifiers::ConsolidatedIdentifier does the same).
        def root
          identifiers&.first&.root || self
        end

        # Co-equal designations, so both matching primitives reduce to the
        # primary one — the Iec::Identifiers::ConsolidatedIdentifier shape.
        def base_document
          identifiers&.first&.base_document || self
        end

        def drop_supplements
          identifiers&.first || self
        end

        def to_s
          parts = render_parts
          result = parts.join(separator || "/")
          result += render_reaffirmation if reaffirmation
          result += package if package
          result
        end

        private

        # With a comma separator every designation carries its full prefix;
        # with a slash the trailing ones are continuations printed bare.
        def render_parts
          return identifiers.map(&:to_s) if separator == ", "

          identifiers.each_with_index.map do |identifier, index|
            index.zero? ? identifier.to_s : render_continuation(identifier)
          end
        end

        # Reaffirmation - preserve original format and determine spacing.
        # A space is needed when the year was printed 2-digit and the
        # reaffirmation 4-digit; the year format comes from the primary
        # designation.
        def render_reaffirmation
          primary = identifiers&.first
          year_was_2digit =
            primary &&
            primary.class.attributes.key?(:original_year_4digit) &&
            !primary.original_year_4digit

          reaffirmation_was_4digit = reaffirmation.to_s.length == 4 &&
            reaffirmation.to_s.start_with?("19", "20")

          if year_was_2digit && reaffirmation_was_4digit
            " (R#{reaffirmation})"
          else
            "(R#{reaffirmation})"
          end
        end

        # Render identifier without CSA prefix (unless has_publisher is true)
        def render_continuation(identifier)
          parts = []

          # Add CSA prefix if present in original
          if identifier.has_publisher
            parts << (identifier.publisher_prefix || "CSA")
          end

          code_part = identifier.number.to_s if identifier.number

          # NO. keyword
          if identifier.no_number
            code_part += " NO. #{identifier.no_number}"
          end

          # Series prefix and keyword (before year)
          if identifier.series_prefix
            code_part += " #{identifier.series_prefix} SERIES"
          elsif identifier.series
            # SERIES without prefix
            code_part += " SERIES"
          end

          code_part += render_continuation_year(identifier) if identifier.year

          parts << code_part if code_part

          join_continuation(identifier, parts)
        end

        # Year with proper format (colon or dash)
        def render_continuation_year(identifier)
          separator = identifier.year_format == "dash" ? "-" : ":"
          year_part = separator
          # Add M or F prefix
          year_part += identifier.year_prefix if identifier.year_prefix
          # Only add F if no prefix
          if identifier.french && identifier.year_format != "dash" &&
              !identifier.year_prefix
            year_part += "F"
          end
          # Convert 4-digit year back to 2-digit
          year_str = identifier.year.to_s
          year_part + if year_str.length == 4 && year_str.start_with?("20")
                        year_str[2..3]
                      else
                        year_str
                      end
        end

        # Join with proper spacing based on prefix
        def join_continuation(identifier, parts)
          return parts.join(" ") unless identifier.has_publisher &&
            parts.length > 1

          prefix = parts[0]
          if prefix.end_with?("-")
            # No space after dash-ending prefix
            prefix + parts[1..].join(" ")
          else
            parts.join(" ")
          end
        end
      end
    end
  end
end
