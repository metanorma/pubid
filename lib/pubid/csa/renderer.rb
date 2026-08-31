# frozen_string_literal: true

module Pubid
  module Csa
    # Human-readable renderer for CSA identifiers that extend Pubid::Identifier.
    #
    # Produces strings like:
    #   "CSA B149.1:20"
    #   "CAN/CSA-C22.2 NO. 60601-1-9:15"
    #   "CSA C22.2 NO. 286:23"
    #   "CSA MH SERIES 3.14:20"
    #
    # The renderer is registered as the +:human+ format in the CSA format
    # registry and invoked via +render(format: :human)+.
    #
    # Note: Some CSA identifier types (Bundled, Combined, CanadianAdopted,
    # CsaAdopted, Package) extend Lutaml::Model::Serializable directly,
    # not Pubid::Identifier, so they keep their own to_s implementations.
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **_opts)
        id = @id
        @context = context

        case id
        when Identifiers::Series
          render_series(id)
        when Identifiers::Cec
          render_cec(id)
        else
          render_base(id)
        end
      end

      private

      # Base rendering: "CSA B149.1:20", "CAN/CSA-C22.2-05"
      def render_base(id)
        prefix = publisher_prefix_for(id)

        # Handle code_only identifiers (empty string means no prefix)
        if prefix == ""
          # No prefix for code_only identifiers
          parts = []
        else
          # Determine if we need space after prefix
          # CAN/CSA- and CAN3- end with dash, so no space needed
          needs_space = !prefix.end_with?("-")

          parts = []
          parts << prefix
        end

        # Code and year together
        code_part = id.number.to_s if id.number

        # NO. keyword
        if id.no_number
          code_part += " NO. #{id.no_number}"
        end

        # Series prefix and keyword (before year)
        if id.series_prefix
          code_part += " #{id.series_prefix} SERIES"
        elsif id.series
          # SERIES without prefix
          code_part += " SERIES"
        end

        parts << code_part if code_part

        # Year with proper format (colon or dash)
        if id.year
          # Use dash if year_format is dash, otherwise colon
          separator = id.year_format == "dash" ? "-" : ":"
          year_part = separator
          year_part += id.year_prefix if id.year_prefix # Add M or F prefix
          year_part += "F" if id.french && id.year_format != "dash" && !id.year_prefix # Only add F if no prefix
          # Convert 4-digit year back to 2-digit for M/F prefix preservation
          # M1983 → M83, F1983 → F83, 1983 → 83, 20xx → xx
          # However, preserve original 4-digit format if the input was 4-digit (original_year_4digit)
          year_str = id.year.to_s
          year_part += if id.original_year_4digit
                         # Preserve 4-digit format (e.g., "M1981" stays "M1981")
                         year_str
                       elsif id.year_prefix&.match?(/^[MF]$/) && year_str.length == 4 && year_str.start_with?("19")
                         # M/F + 4-digit year (1900s) → convert to 2-digit with prefix
                         year_str[2..3]
                       elsif year_str.length == 4 && year_str.start_with?("20")
                         # 2000s → just last 2 digits
                         year_str[2..3]
                       elsif year_str.length == 4 && year_str.start_with?("19") && !id.original_year_4digit
                         # 1900s with no M/F prefix, but original was 2-digit (e.g., CAN3-Z299.0-86)
                         # Convert back to 2-digit
                         year_str[2..3]
                       else
                         # Other formats - keep as-is
                         year_str
                       end
          parts[-1] += year_part
        end

        result = if prefix == ""
                   # No prefix, just join parts
                   parts.join(" ")
                 elsif !prefix.end_with?("-")
                   parts.join(" ")
                 elsif parts.length == 2
                   # No space after dash-ending prefix - join first two parts directly
                   # If there are more parts after code, they should still have spaces
                   parts.join
                 else
                   # More than 2 parts shouldn't happen in current design
                   parts.join
                 end

        # Reaffirmation - preserve original format and determine spacing
        if id.reaffirmation && !id.reaffirmation.to_s.empty?
          result += render_reaffirmation(id)
        end

        # Package (already has leading space from parser)
        if id.package
          result += id.package
        end

        result
      end

      # CEC rendering: "CSA C22.2 NO. 286:23"
      def render_cec(id)
        parts = []

        # Publisher prefix (CSA, CAN/CSA-, CAN3-)
        prefix = publisher_prefix_for(id)

        # Determine if we need space after prefix
        # CAN/CSA- and CAN3- end with dash, so no space needed
        needs_space = !prefix.end_with?("-")

        parts << prefix unless prefix == ""

        # CEC Part (C22.2, C22.3, etc.)
        parts << id.cec_part.render(context: @context) if id.cec_part

        # NO. notation - this is the key semantic component
        parts << "NO."

        # Number after NO.
        parts << id.no_number.render(context: @context) if id.no_number

        # Determine separator based on prefix ending
        result = if prefix == ""
                   parts.join(" ")
                 elsif needs_space
                   parts.join(" ")
                 elsif parts.length <= 2
                   # No space after dash-ending prefix (CAN/CSA-, CAN3-)
                   # Join first two parts directly, rest with spaces
                   parts.join
                 else
                   parts[0] + parts[1..].join(" ")
                 end

        # Year with proper format (colon or dash)
        if id.year
          # Use dash if year_format is dash, otherwise colon
          separator = id.year_format == "dash" ? "-" : ":"
          year_part = separator

          # Convert 4-digit year back to 2-digit for display
          year_str = id.year.to_s
          display_year = if year_str.length == 4 && year_str.start_with?("20")
                           year_str[2..3]
                         elsif year_str.length == 4 && year_str.start_with?("19")
                           year_str[2..3]
                         else
                           year_str
                         end

          # Add prefix if present
          year_part += if id.year_prefix
                         id.year_prefix + display_year
                       elsif id.french && id.year_format != "dash"
                         # Only add F if no prefix already set
                         "F#{display_year}"
                       else
                         display_year
                       end

          result += year_part
        end

        # Reaffirmation
        if id.reaffirmation && !id.reaffirmation.to_s.empty?
          result += render_reaffirmation(id)
        end

        result
      end

      # Series rendering: "CSA MH SERIES 3.14:20"
      def render_series(id)
        result = series_publisher_prefix_portion(id)

        # Add code FIRST (before SERIES keyword)
        result += id.number.to_s

        # Add space before series prefix/SERIES keyword
        result += " "

        # Add series prefix if present
        result += "#{id.series_prefix} " if id.series_prefix && !id.series_prefix.empty?

        # Add SERIES keyword
        result += "SERIES"

        # Add year
        result += series_year_portion(id)

        # Add reaffirmation
        result += render_reaffirmation(id) if id.reaffirmation && !id.reaffirmation.to_s.empty?

        result
      end

      private

      # Reaffirmation rendering helper - shared across Base, Cec, and Series
      def render_reaffirmation(id)
        # Check if year was originally 2-digit (original_year_4digit flag)
        year_was_2digit = !id.original_year_4digit

        # Check if reaffirmation was originally 4-digit (original_reaffirmation_4digit flag)
        reaffirmation_was_4digit = id.original_reaffirmation_4digit

        # Preserve original reaffirmation format
        reaffirmation_str = if reaffirmation_was_4digit
                              # Original was 4-digit, keep as-is
                              id.reaffirmation.to_s
                            elsif id.reaffirmation.to_s.length == 4 && id.reaffirmation.to_s.start_with?("19", "20")
                              # Original was 2-digit, convert 4-digit storage back to 2-digit
                              id.reaffirmation.to_s[2..3]
                            else
                              # Already 2-digit or other format
                              id.reaffirmation.to_s
                            end

        # Determine spacing based on original formats
        if year_was_2digit && reaffirmation_was_4digit
          # Year was 2-digit, reaffirmation was 4-digit → add space
          " (R#{reaffirmation_str})"
        else
          # Both 2-digit, both 4-digit, or other cases → no space
          "(R#{reaffirmation_str})"
        end
      end

      # The publisher prefix to print. A code_only identifier printed none, so
      # it must not gain the default "CSA" — see SingleIdentifier#code_only.
      def publisher_prefix_for(id)
        return "" if id.respond_to?(:code_only) && id.code_only

        id.publisher_prefix || "CSA"
      end

      def series_publisher_prefix_portion(id)
        prefix = publisher_prefix_for(id)

        # Handle code_only identifiers (empty string means no prefix)
        return "" if prefix == ""

        # Determine if we need space after prefix
        # CAN/CSA- and CAN3- end with dash, so no space needed
        needs_space = !prefix.end_with?("-")

        needs_space ? "#{prefix} " : prefix
      end

      def series_year_portion(id)
        return "" unless id.year

        # Use dash if year_format is dash, otherwise colon
        separator = id.year_format == "dash" ? "-" : ":"
        year_part = separator
        year_part += id.year_prefix if id.year_prefix # Add M or F prefix
        year_part += "F" if id.french && id.year_format != "dash" && !id.year_prefix # Only add F if no prefix

        # Convert 4-digit year back to 2-digit
        year_str = id.year.to_s
        year_part += if year_str.length == 4 && year_str.start_with?("20")
                       year_str[2..3]
                     else
                       year_str
                     end

        year_part
      end
    end
  end
end
