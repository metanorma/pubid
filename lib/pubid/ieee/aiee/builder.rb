# frozen_string_literal: true

module Pubid
  module Ieee
    module Aiee
      # Builder for AIEE identifiers
      class Builder
        def build(parsed)
          attributes = {}

          # Extract and normalize publisher
          # All AIEE variants (AIEE, A.I.E.E., A. I. E. E., IEEE-AIEE) normalize to "AIEE"
          attributes[:publisher] = "AIEE"

          # Extract and normalize type
          type_str = extract_value(parsed[:type])
          # Normalize compound types like "Standard No." to "No"
          # Also normalize "Standard No" (without dot) to "No"
          attributes[:type] = if type_str&.start_with?("Standard")
                                "No"
                              else
                                type_str
                              end

          # Extract code
          code_str = extract_number(parsed[:number])
          if code_str
            attributes[:code] = Components::Code.parse(code_str)
          end

          # Extract year (convert to string for consistency)
          year_str = extract_value(parsed[:year])
          attributes[:year] = year_str&.to_s

          # Extract month
          month_str = extract_value(parsed[:month])
          attributes[:month] = month_str if month_str

          # Extract the long-form date separator ("," or ".") for rendering.
          # Named `date_separator` on the identifier to avoid colliding with the
          # CodeNumber code-part `separator`.
          separator_str = extract_value(parsed[:separator])
          attributes[:date_separator] = separator_str if separator_str

          # Set original format based on parsed data
          attributes[:original_format] = if separator_str || month_str
                                           "long"
                                         else
                                           "short"
                                         end

          # Create identifier
          Identifier.new(**attributes)
        end

        private

        # Extract the number, flattening a "431 (105)" main-number/parenthetical
        # subtree into a plain string. Without this, a Hash node leaks its raw
        # Parslet inspect form (e.g. `{main_number: "431"@8, ...}`) into `to_s`.
        def extract_number(value)
          return extract_value(value) unless value.is_a?(Hash)

          main = extract_value(value[:main_number])
          paren = value[:parenthetical]
          alt = paren.is_a?(Hash) ? extract_value(paren[:alt_number]) : nil
          alt ? "#{main} (#{alt})" : main
        end

        def extract_value(value)
          return nil if value.nil?
          return nil if value.is_a?(Array) && value.empty?

          if value.is_a?(Array)
            joined = value.join
            return joined.length.positive? ? joined : nil
          end

          str_value = value.to_s.strip
          str_value.length.positive? ? str_value : nil
        end
      end
    end
  end
end
