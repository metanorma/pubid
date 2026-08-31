# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Csa
    module Identifiers
      class Bundled < Identifier
        # The consolidated base document and the amendments bundled with it.
        # Both are typed cross-flavor and polymorphic — see
        # WrapperIdentifier#base — because a bundle's base is routinely a Cec,
        # which is not a Standard subclass. #root is inherited: it walks
        # `base` to the origin document.
        attribute :base, ::Pubid::Identifier, polymorphic: true
        attribute :bundled_with, ::Pubid::Identifier, polymorphic: true,
                                                      collection: true
        attribute :reaffirmation, :string
        attribute :original_reaffirmation_4digit, :boolean, default: -> {
          false
        }
        attribute :year_format, :string # Add for compatibility with identifier.rb

        # A bundle is a base document consolidated with its amendments, so
        # both matching primitives peel to that base.
        def base_document
          base ? base.base_document : self
        end

        def drop_supplements
          base || self
        end

        def to_s
          # For Cec identifiers, use normalized form (number instead of cec_part + NO.)
          # This is used for "normalized form" rendering in bundled identifiers
          if base.is_a?(Cec)
            # Render base with normalized code format
            prefix = base.publisher_prefix || "CSA"
            needs_space = !prefix.end_with?("-")
            # Convert 4-digit year back to 2-digit for display
            year_display = if base.year
                             year_str = base.year.to_s
                             if year_str.length == 4 && year_str.start_with?("20")
                               year_str[2..3]
                             else
                               year_str
                             end
                           end
            base_str = (needs_space ? "#{prefix} " : prefix) +
              base.number.value.to_s + # Normalized code (e.g. "C22.2-1")
              ":#{year_display}"
            parts = [base_str]
          else
            # Standard rendering for other identifier types
            parts = [base.to_s]
          end

          # Add bundled amendments/supplements (without CSA prefix)
          if bundled_with && !bundled_with.empty?
            bundled_with.each do |bundled|
              # For Cec identifiers, use normalized code format
              if bundled.is_a?(Cec)
                bundled_part = bundled.number.value.to_s # e.g. "C22.2-2"
                if bundled.year
                  # Use dash if year_format is dash, otherwise colon
                  separator = bundled.year_format == "dash" ? "-" : ":"
                  bundled_part += separator
                  bundled_part += bundled.year_prefix if bundled.year_prefix # Add M or F prefix
                  bundled_part += "F" if bundled.french && bundled.year_format != "dash" && !bundled.year_prefix
                  # Convert 4-digit year back to 2-digit
                  year_str = bundled.year.to_s
                  bundled_part += if year_str.length == 4 && year_str.start_with?("20")
                                    year_str[2..3]
                                  else
                                    year_str
                                  end
                end
              else
                # Standard rendering for other identifier types
                bundled_part = ""
                bundled_part += bundled.number.to_s if bundled.number

                if bundled.year
                  # Use dash if year_format is dash, otherwise colon
                  separator = bundled.year_format == "dash" ? "-" : ":"
                  bundled_part += separator
                  bundled_part += bundled.year_prefix if bundled.year_prefix # Add M or F prefix
                  bundled_part += "F" if bundled.french && bundled.year_format != "dash" && !bundled.year_prefix # Only add F if no prefix
                  # Convert 4-digit year back to 2-digit
                  # Use original_year_4digit flag to determine original format
                  year_str = bundled.year.to_s
                  bundled_part += if bundled.class.attributes.key?(:original_year_4digit) && bundled.original_year_4digit
                                    # Preserve 4-digit format
                                    year_str
                                  elsif year_str.length == 4 && year_str.start_with?("20")
                                    # 2000s → convert to 2-digit
                                    year_str[2..3]
                                  elsif year_str.length == 4 && year_str.start_with?("19") && bundled.class.attributes.key?(:original_year_4digit) && !bundled.original_year_4digit
                                    # 1900s with no M/F prefix, but original was 2-digit (e.g., bundled identifier)
                                    # Convert back to 2-digit
                                    year_str[2..3]
                                  else
                                    # Other formats - keep as-is
                                    year_str
                                  end
                end
              end

              parts << bundled_part
            end
          end

          result = parts.join(" + ")

          # Reaffirmation - preserve original format and determine spacing
          if reaffirmation
            # For bundled identifiers, check year format from base identifier
            # to determine spacing
            year_was_2digit = base.class.attributes.key?(:original_year_4digit) && !base.original_year_4digit

            # Check if reaffirmation was originally 4-digit
            # Note: We need to track this at the Bundled level, but for now
            # assume 4-digit if the value is 4 digits and starts with 19/20
            reaffirmation_was_4digit = reaffirmation.to_s.length == 4 &&
              reaffirmation.to_s.start_with?("19", "20")

            # Determine spacing based on original formats
            # Space needed if year is 2-digit and reaffirmation is 4-digit
            result += if year_was_2digit && reaffirmation_was_4digit
                        " (R#{reaffirmation})"
                      else
                        "(R#{reaffirmation})"
                      end
          end

          result
        end
      end
    end
  end
end
