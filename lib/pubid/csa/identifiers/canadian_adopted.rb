# frozen_string_literal: true

module Pubid
  module Csa
    module Identifiers
      # CanadianAdoptedIdentifier represents Canadian adoption of standards
      # indicated by the CAN/ prefix wrapper.
      #
      # Examples:
      #   CAN/CSA-C22.2 NO. 60601-1-9:15
      #   CAN/CSA-Z662:23 (R2024)
      #
      # This is a wrapper pattern where:
      #   - CAN/ indicates Canadian adoption
      #   - The base is the actual CSA standard being adopted
      #
      # This is semantically different from a string prefix because:
      #   - CAN/ wraps an entire identifier (which may itself be complex)
      #   - The wrapped identifier is recursively parsed as a full CSA identifier
      #   - Proper object composition, not string manipulation
      class CanadianAdopted < WrapperIdentifier
        def to_s
          # For CAN3- identifiers, don't add CAN/ prefix (CAN3- is already complete)
          # For Series with CAN/CSA- prefix, don't add CAN/ (it's already complete)
          # For CAN/CSA- identifiers, CAN/ wraps CSA- part
          if base.class.attributes.key?(:publisher_prefix) && base.publisher_prefix
            prefix = base.publisher_prefix
            # CAN3- is standalone, just render wrapped identifier
            # CAN/CSA- is already complete for Series identifiers
            if prefix == "CAN3-" || (prefix == "CAN/CSA-" && base.is_a?(Identifiers::Series))
              result = base.to_s
            else
              # For other cases, prepend CAN/ prefix
              result = "CAN/#{base}"
            end
          else
            # No publisher_prefix, prepend CAN/
            result = "CAN/#{base}"
          end
          # Only add reaffirmation from wrapper if base doesn't have one
          # (to avoid duplicates - Identifier.parse sets it on both)
          if reaffirmation && !(base.class.attributes.key?(:reaffirmation) && base.reaffirmation)
            # Determine if space is needed before reaffirmation
            # Space needed if year is 2-digit and reaffirmation is 4-digit (original format)
            # No space if both year and reaffirmation are 2-digit
            # Check original_year_4digit flag - if false, year was originally 2-digit
            year_was_2digit = base.class.attributes.key?(:original_year_4digit) &&
              !base.original_year_4digit
            # Check original_reaffirmation_4digit flag
            reaffirmation_was_4digit = original_reaffirmation_4digit

            # Preserve original reaffirmation format
            # If original was 4-digit, keep as 4-digit
            # If original was 2-digit, convert from 4-digit storage back to 2-digit
            reaffirmation_str = if reaffirmation_was_4digit
                                  # Original was 4-digit, keep as-is
                                  reaffirmation.to_s
                                elsif reaffirmation.to_s.length == 4 && reaffirmation.to_s.start_with?(
                                  "19", "20"
                                )
                                  # Original was 2-digit, convert 4-digit storage back to 2-digit
                                  # (R2004) → (R04), (R1994) → (R94)
                                  reaffirmation.to_s[2..3]
                                else
                                  # Already 2-digit or other format
                                  reaffirmation.to_s
                                end

            if year_was_2digit && reaffirmation_was_4digit
              # Year was 2-digit, reaffirmation was 4-digit → add space
              result += " (R#{reaffirmation_str})"
            else
              # Both 2-digit or other cases → no space
              result += "(R#{reaffirmation_str})"
            end
          end
          result
        end
      end
    end
  end
end
