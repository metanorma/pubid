# frozen_string_literal: true

module Pubid
  module Csa
    module Identifiers
      # CsaAdoptedIdentifier represents CSA adoption of international standards
      # (ISO, IEC, ISO/IEC, CISPR, etc.)
      #
      # Examples:
      #   CSA ISO/IEC TR 12785-3:15
      #   CSA ISO/IEC TR 19758:04 (R2024)
      #   CSA CISPR 16-1-1:18
      #   CSA-ISO 10012:03 (when wrapped by CanadianAdopted)
      #
      # Key difference from CanadianAdopted:
      #   - CsaAdopted wraps ISO/IEC/CISPR standards (external)
      #   - CanadianAdopted wraps CSA standards (internal)
      #
      # This is a wrapper pattern where:
      #   - CSA prefix indicates adoption
      #   - The base is the external standard (ISO/IEC/CISPR)
      #   - Wrapped identifier is recursively parsed using external flavor parsers
      class CsaAdopted < WrapperIdentifier
        # Publisher prefix (e.g., "CSA-", "CAN3-") for rendering
        # When set, uses dash format without space (e.g., "CSA-ISO" not "CSA ISO")
        attribute :publisher_prefix, :string

        def to_s
          # Get string representation from wrapped identifier
          base_str = base.to_s

          # Convert 4-digit years to 2-digit for CSA adoption format
          # ISO/IEC TR 12785-3:2015 → ISO/IEC TR 12785-3:15
          # Also handle amendment years: /Amd 1:2022 → /A1:22
          if base_str =~ /:(\d{4})\b/
            year = $1
            if year.start_with?("20")
              short_year = year[2..3]
              base_str = base_str.sub(":#{year}", ":#{short_year}")
            elsif year.start_with?("19")
              # Handle 1900s years: 1998 → 98
              short_year = year[2..3]
              base_str = base_str.sub(":#{year}", ":#{short_year}")
            end
          end

          # Convert ISO/IEC amendment format to CSA format
          # /Amd 1:22 → /A1:22, /Amd 1-22 → /A1-22
          # Handle both 2-digit and 4-digit years
          base_str = base_str.gsub(%r{/Amd\s+(\d+)([:/-])(\d{2,4})\b}) do |_match|
            amendment_num = $1
            separator = $2
            amend_year = $3
            # Convert 4-digit year to 2-digit if needed
            if amend_year.length == 4 && amend_year.start_with?("20", "19")
              amend_year = amend_year[2..3]
            end
            "/A#{amendment_num}#{separator}#{amend_year}"
          end

          # Apply publisher prefix format
          # If publisher_prefix is "CSA-", render as "CSA-ISO..." (no space)
          # Otherwise render as "CSA ISO..." (with space)
          result = if publisher_prefix&.end_with?("-")
                     "#{publisher_prefix}#{base_str}"
                   else
                     "CSA #{base_str}"
                   end

          # Append reaffirmation if present
          result += " (R#{reaffirmation})" if reaffirmation

          result
        end
      end
    end
  end
end
