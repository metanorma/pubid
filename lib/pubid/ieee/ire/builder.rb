# frozen_string_literal: true

module Pubid
  module Ieee
    module Ire
      # Builder for IRE identifiers
      class Builder
        def build(parsed)
          attributes = {}

          # Extract publisher
          attributes[:publisher] = extract_value(parsed[:publisher])

          # Extract type
          attributes[:type] = extract_value(parsed[:type])

          # Extract the document designation. It travels as `code:` so the base
          # initializer parses it into `code_obj` and the CodeNumber mixin
          # hoists the flat split columns (number/prefix/parts/separator) that
          # relaton indexes on.
          number_str = extract_value(parsed[:number])
          attributes[:code] = number_str if number_str

          # Extract year - handle both short (52) and full (1952) formats
          year_str = extract_value(parsed[:year])
          if year_str
            year_int = year_str.to_i
            # Convert 2-digit years to 4-digit (12-63 => 1912-1963)
            if year_int.between?(12, 63)
              year_int += 1900
            end
            attributes[:year] = year_int.to_s
          end

          # Override with full_year if present
          full_year_str = extract_value(parsed[:full_year])
          if full_year_str
            attributes[:year] = full_year_str.to_i.to_s
          end

          # Create identifier
          Identifier.new(**attributes)
        end

        private

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
