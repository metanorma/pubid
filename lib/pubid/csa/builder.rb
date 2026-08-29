# frozen_string_literal: true

module Pubid
  module Csa
    class Builder
      def build(parsed_hash)
        # Handle Canadian adopted identifiers (CAN/CSA- or CAN3- prefix)
        # Check this BEFORE series_type because CAN/CSA-X SERIES:YY should be
        # CanadianAdopted wrapping a Series, not a plain Series identifier
        if parsed_hash[:publisher_prefix] &&
            ["CAN/CSA-", "CAN3-"].include?(parsed_hash[:publisher_prefix].to_s)
          return build_canadian_adopted(parsed_hash)
        end

        # Handle adoption identifiers (ISO/IEC/CISPR/CEI adoptions)
        if parsed_hash.key?(:adoption_number)
          return build_adoption(parsed_hash)
        end

        # Handle series identifiers (SERIES as primary type)
        if parsed_hash.key?(:series_type)
          return build_series(parsed_hash)
        end

        # Handle CEC identifiers (C22.x NO. patterns)
        if parsed_hash.key?(:cec_part)
          return build_cec(parsed_hash)
        end

        # Handle package identifiers (with package_portion marker)
        if parsed_hash.key?(:package_portion)
          return build_package(parsed_hash)
        end

        # Handle bundled identifiers (with + notation)
        if parsed_hash.key?(:bundled_first)
          return build_bundled(parsed_hash)
        end

        # Handle combined identifiers (with / notation)
        if parsed_hash[:first] && parsed_hash[:second]
          return build_combined(parsed_hash)
        end

        build_single(parsed_hash)
      end

      private

      def build_package(parsed_hash)
        package = Identifiers::Package.new

        # Build base identifier (without package_portion)
        base_data = parsed_hash.dup
        base_data.delete(:package_portion)
        package.base = build_single(base_data)

        # Set package materials
        if parsed_hash[:package_portion]
          package.package_materials = parsed_hash[:package_portion].to_s
        end

        package
      end

      def build_adoption(parsed_hash)
        adoption = Identifiers::CsaAdopted.new

        # Get the organization prefix (ISO/IEC, ISO, IEC, CISPR, CEI/IEC)
        adoption_org = parsed_hash[:adoption_org].to_s
        adoption_number = parsed_hash[:adoption_number].to_s
        adoption_year = parsed_hash[:adoption_year].to_s

        # Add ISO type (TR/TS) if present
        if parsed_hash[:iso_type]
          adoption_org += " #{parsed_hash[:iso_type]}"
        end

        # Year separator for wrapped identifier
        year_sep = parsed_hash[:adoption_year_sep] || ":"

        # Build the wrapped identifier string for the external standard
        # Convert 2-digit year to 4-digit for external parser
        wrapped_year = if adoption_year.length == 2
                         "20#{adoption_year}"
                       else
                         adoption_year
                       end

        # Handle amendment if present
        if parsed_hash[:adoption_amendment]
          # There's an amendment, build Amendment identifier
          # Build base identifier string
          base_str = "#{adoption_org} #{adoption_number}#{year_sep}#{wrapped_year}"

          # Parse base identifier
          if adoption_org.start_with?("ISO", "CEI")
            Pubid::Iso.parse(base_str)
          elsif adoption_org.start_with?("IEC")
            Pubid::Iec.parse(base_str)
          else
            begin
              Pubid::Iso.parse(base_str)
            rescue Parslet::ParseFailed
              Pubid::Iec.parse(base_str)
            end
          end

          # Build amendment string for external parser
          amendment_year = parsed_hash[:adoption_amendment_year].to_s
          wrapped_amendment_year = if amendment_year.length == 2
                                     "20#{amendment_year}"
                                   else
                                     amendment_year
                                   end

          # The external parser uses Amendment class which wraps the base
          # We need to construct the amendment identifier
          # For ISO: "ISO/IEC 9594-2:2021/Amd 1:2022"
          # For IEC: similar format

          if adoption_org.start_with?("ISO", "CEI")
          # ISO format
          elsif adoption_org.start_with?("IEC")
          # IEC format
          else
            # CISPR or other
          end
          amendment_str = "#{base_str}/Amd #{parsed_hash[:adoption_amendment]}:#{wrapped_amendment_year}"

          base = if adoption_org.start_with?("ISO", "CEI")
                   Pubid::Iso.parse(amendment_str)
                 elsif adoption_org.start_with?("IEC")
                   Pubid::Iec.parse(amendment_str)
                 else
                   begin
                     Pubid::Iso.parse(amendment_str)
                   rescue Parslet::ParseFailed
                     Pubid::Iec.parse(amendment_str)
                   end
                 end
        else
          # No amendment, simple base identifier
          wrapped_id_str = "#{adoption_org} #{adoption_number}#{year_sep}#{wrapped_year}"

          # CEI/IEC is normalized to IEC for parsing
          if adoption_org == "CEI/IEC"
            wrapped_id_str = wrapped_id_str.sub("CEI/IEC", "IEC")
          end

          base = if adoption_org.start_with?("ISO", "CEI")
                   Pubid::Iso.parse(wrapped_id_str)
                 elsif adoption_org.start_with?("IEC")
                   Pubid::Iec.parse(wrapped_id_str)
                 else
                   begin
                     Pubid::Iso.parse(wrapped_id_str)
                   rescue Parslet::ParseFailed
                     Pubid::Iec.parse(wrapped_id_str)
                   end
                 end
        end

        adoption.base = base

        # Handle reaffirmation
        if parsed_hash[:reaffirmation]
          reaffirm_data = parsed_hash[:reaffirmation]
          adoption.reaffirmation = if reaffirm_data.is_a?(Hash) && reaffirm_data[:year]
                                     reaffirm_data[:year].to_s
                                   else
                                     reaffirm_data.to_s
                                   end
        end

        adoption
      end

      def build_canadian_adopted(parsed_hash)
        canadian_adopted = Identifiers::CanadianAdopted.new

        # Store the original publisher_prefix (CAN/CSA- or CAN3-)
        original_prefix = parsed_hash[:publisher_prefix]&.to_s

        # Build the wrapped identifier based on what the parser matched
        # The parser may have matched series_identifier, cec_identifier, or csa_code
        # We build the appropriate wrapped type based on the presence of specific keys
        wrapped_data = parsed_hash.dup

        # Remove publisher_prefix from wrapped_data so the wrapped identifier
        # doesn't also include the prefix (we only want it on the CanadianAdopted wrapper)
        # But for Series with CAN/CSA- prefix, the to_s method expects the Series
        # to have publisher_prefix = "CAN/CSA-" to render correctly
        if parsed_hash.key?(:series_type)
          # SERIES matched - build Series identifier with CAN/CSA- prefix
          # The Series.to_s will handle rendering as "CAN/CSA-A220 SERIES-06"
          # (keeping the full prefix instead of "CAN/CSA-A220...")
          base = build_series(wrapped_data)
          # Set the full publisher_prefix on the wrapped Series for proper rendering
          # The test expects base.publisher_prefix to be "CAN/CSA-"
        elsif parsed_hash.key?(:cec_part)
          # CEC matched - build Cec identifier
          base = build_cec(wrapped_data)
        else
          # Standard CSA identifier
          base = build_single(wrapped_data)
        end
        base.publisher_prefix = original_prefix if original_prefix && base.class.attributes.key?(:publisher_prefix)

        canadian_adopted.base = base

        # Handle reaffirmation - supports both 2-digit and 4-digit years.
        # The wrapper's own original_reaffirmation_4digit is left at its
        # default: CanadianAdopted#to_s only consults it when the wrapped id
        # carries no reaffirmation of its own, and Series/Cec track the printed
        # width themselves.
        if parsed_hash[:reaffirmation_4digit]
          # Original was 4-digit (e.g., "R2019")
          canadian_adopted.reaffirmation = parsed_hash[:reaffirmation_4digit].to_s
        elsif parsed_hash[:reaffirmation_2digit]
          # Original was 2-digit (e.g., "R19"), convert to 4-digit for internal storage
          year_2digit = parsed_hash[:reaffirmation_2digit].to_s
          year_int = year_2digit.to_i
          canadian_adopted.reaffirmation = year_int < 50 ? "20#{year_2digit}" : "19#{year_2digit}"
        elsif parsed_hash[:reaffirmation]
          # Legacy format (Hash or String)
          reaffirm_data = parsed_hash[:reaffirmation]
          canadian_adopted.reaffirmation = if reaffirm_data.is_a?(Hash) && reaffirm_data[:year]
                                             reaffirm_data[:year].to_s
                                           else
                                             reaffirm_data.to_s
                                           end
        end

        canadian_adopted
      end

      def build_series(parsed_hash)
        series = Identifiers::Series.new

        # Series identifiers always have series = true (this is how they're identified)
        series.series = true

        # Publisher prefix
        if parsed_hash[:publisher_prefix]
          series.publisher_prefix = parsed_hash[:publisher_prefix].to_s
        end

        # Series prefix (MH, RV, etc.)
        if parsed_hash[:series_prefix]
          series.series_prefix = parsed_hash[:series_prefix].to_s
        end

        # Code
        if parsed_hash[:code]
          series.number = Components::Code.new(value: parsed_hash[:code].to_s)
        end

        # Year format and year
        year_format = if parsed_hash[:dash_format]
                        "dash"
                      elsif parsed_hash[:colon_format]
                        "colon"
                      else
                        "colon" # default
                      end

        if parsed_hash[:year]
          year_str = parsed_hash[:year].to_s
          if year_str.length == 2
            # Convert 2-digit year to 4-digit
            # Rule: 00-49 → 2000s, 50-99 → 1900s
            # M prefix also means 1900s (metric/old standards)
            year_int = year_str.to_i
            if parsed_hash[:year_prefix] && parsed_hash[:year_prefix].to_s == "M"
              # M prefix always means 1900s
              series.year = "19#{year_str}"
            elsif year_int < 50
              # 00-49 → 2000s
              series.year = "20#{year_str}"
            else
              # 50-99 → 1900s
              series.year = "19#{year_str}"
            end
          else
            # Keep 4-digit years as-is AND mark original format
            series.year = year_str
            series.original_year_4digit = true
          end
          series.year_format = year_format
        end

        # Year prefix (F or M)
        if parsed_hash[:year_prefix]
          series.year_prefix = parsed_hash[:year_prefix].to_s
        end

        # Reaffirmation - supports both 2-digit and 4-digit years
        # Tracks original format via original_reaffirmation_4digit flag
        # Check NEW parser keys first (outside of legacy :reaffirmation check)
        if parsed_hash[:reaffirmation_4digit]
          # Original was 4-digit (e.g., "R2019")
          series.reaffirmation = parsed_hash[:reaffirmation_4digit].to_s
          series.original_reaffirmation_4digit = true
        elsif parsed_hash[:reaffirmation_2digit]
          # Original was 2-digit (e.g., "R19"), convert to 4-digit for internal storage
          year_2digit = parsed_hash[:reaffirmation_2digit].to_s
          year_int = year_2digit.to_i
          series.reaffirmation = year_int < 50 ? "20#{year_2digit}" : "19#{year_2digit}"
          series.original_reaffirmation_4digit = false
        elsif parsed_hash[:reaffirmation]
          # Legacy format (Hash or String)
          reaffirm_data = parsed_hash[:reaffirmation]
          series.reaffirmation = if reaffirm_data.is_a?(Hash) && reaffirm_data[:year]
                                   reaffirm_data[:year].to_s
                                 else
                                   reaffirm_data.to_s
                                 end
        end

        series
      end

      def build_cec(parsed_hash)
        cec = Identifiers::Cec.new

        # Publisher prefix (if set)
        if parsed_hash[:publisher_prefix]
          cec.publisher_prefix = parsed_hash[:publisher_prefix].to_s
        end

        # CEC part (C22.2, C22.3, etc.)
        if parsed_hash[:cec_part]
          cec.cec_part = Components::Code.new(value: parsed_hash[:cec_part].to_s)
        end

        # NO. number
        if parsed_hash[:no_number]
          cec.no_number = Components::Code.new(value: parsed_hash[:no_number].to_s)
        end

        # Year format and year
        year_format = if parsed_hash[:dash_format]
                        "dash"
                      elsif parsed_hash[:colon_format]
                        "colon"
                      else
                        "colon" # default
                      end

        if parsed_hash[:year]
          year_str = parsed_hash[:year].to_s
          if year_str.length == 2
            # Convert 2-digit year to 4-digit
            # Rule: 00-49 → 2000s, 50-99 → 1900s
            # M prefix also means 1900s (metric/old standards)
            year_int = year_str.to_i
            cec.year = if parsed_hash[:year_prefix] && parsed_hash[:year_prefix].to_s == "M"
                         # M prefix always means 1900s
                         "19#{year_str}"
                       elsif year_int < 50
                         # 00-49 → 2000s
                         "20#{year_str}"
                       else
                         # 50-99 → 1900s
                         "19#{year_str}"
                       end
          else
            # Keep 4-digit years as-is AND mark original format
            cec.year = year_str
            cec.original_year_4digit = true
          end
          cec.year_format = year_format
        end

        # Year prefix (F or M)
        if parsed_hash[:year_prefix]
          cec.year_prefix = parsed_hash[:year_prefix].to_s
          # If year prefix is F, set french flag
          if parsed_hash[:year_prefix].to_s == "F"
            cec.french = true
          end
        end

        # French flag
        if parsed_hash[:french]
          cec.french = true
        end

        # Reaffirmation - supports both 2-digit and 4-digit years
        # Tracks original format via original_reaffirmation_4digit flag
        # Check NEW parser keys first (outside of legacy :reaffirmation check)
        if parsed_hash[:reaffirmation_4digit]
          # Original was 4-digit (e.g., "R2019")
          cec.reaffirmation = parsed_hash[:reaffirmation_4digit].to_s
          cec.original_reaffirmation_4digit = true
        elsif parsed_hash[:reaffirmation_2digit]
          # Original was 2-digit (e.g., "R19"), convert to 4-digit for internal storage
          year_2digit = parsed_hash[:reaffirmation_2digit].to_s
          year_int = year_2digit.to_i
          cec.reaffirmation = year_int < 50 ? "20#{year_2digit}" : "19#{year_2digit}"
          cec.original_reaffirmation_4digit = false
        elsif parsed_hash[:reaffirmation]
          # Legacy format (Hash or String)
          reaffirm_data = parsed_hash[:reaffirmation]
          cec.reaffirmation = if reaffirm_data.is_a?(Hash)
                                reaffirm_data[:year].to_s
                              else
                                reaffirm_data.to_s
                              end
        end

        cec
      end

      def build_bundled(parsed_hash)
        bundled = Identifiers::Bundled.new

        # Build base identifier
        bundled.base = build_single(parsed_hash[:base])

        # Build bundled portions (amendments/supplements)
        # Combine bundled_first with bundled_rest array
        bundled_portions = [parsed_hash[:bundled_first]]
        if parsed_hash[:bundled_rest] && !parsed_hash[:bundled_rest].empty?
          bundled_portions += parsed_hash[:bundled_rest]
        end

        bundled.bundled_with = bundled_portions.map do |portion|
          build_single(portion)
        end

        # Reaffirmation - supports both 2-digit and 4-digit years
        # Tracks original format via original_reaffirmation_4digit flag
        if parsed_hash[:reaffirmation_4digit]
          # Original was 4-digit (e.g., "R2019")
          bundled.reaffirmation = parsed_hash[:reaffirmation_4digit].to_s
          bundled.original_reaffirmation_4digit = true
        elsif parsed_hash[:reaffirmation_2digit]
          # Original was 2-digit (e.g., "R19"), convert to 4-digit for internal storage
          year_2digit = parsed_hash[:reaffirmation_2digit].to_s
          year_int = year_2digit.to_i
          bundled.reaffirmation = year_int < 50 ? "20#{year_2digit}" : "19#{year_2digit}"
          bundled.original_reaffirmation_4digit = false
        elsif parsed_hash[:reaffirmation]
          # Legacy format (String)
          bundled.reaffirmation = parsed_hash[:reaffirmation].to_s
        end

        bundled
      end

      def build_combined(parsed_hash)
        combined = Identifiers::Combined.new

        # Build each designation, in printed order, into one collection.
        combined.identifiers = %i[first second third]
          .filter_map { |key| parsed_hash[key] }
          .map { |part| build_single(part) }

        # Detect separator from parser marker
        combined.separator = if parsed_hash[:comma_separator]
                               # Combined comma: "CSA X, CSA Y"
                               ", "
                             else
                               # Combined slash: "CSA X/Y" (default)
                               "/"
                             end

        # Reaffirmation - supports both 2-digit and 4-digit years
        # Tracks original format via original_reaffirmation_4digit flag
        if parsed_hash[:reaffirmation_4digit]
          # Original was 4-digit (e.g., "R2019")
          combined.reaffirmation = parsed_hash[:reaffirmation_4digit].to_s
          combined.original_reaffirmation_4digit = true
        elsif parsed_hash[:reaffirmation_2digit]
          # Original was 2-digit (e.g., "R19"), convert to 4-digit for internal storage
          year_2digit = parsed_hash[:reaffirmation_2digit].to_s
          year_int = year_2digit.to_i
          combined.reaffirmation = year_int < 50 ? "20#{year_2digit}" : "19#{year_2digit}"
          combined.original_reaffirmation_4digit = false
        elsif parsed_hash[:reaffirmation]
          # Legacy format (String)
          combined.reaffirmation = parsed_hash[:reaffirmation].to_s
        end

        # Handle package portion if present
        if parsed_hash[:package_portion]
          combined.package = parsed_hash[:package_portion].to_s
        end

        combined
      end

      def build_single(data)
        # Select appropriate identifier class based on MECE criteria
        identifier_class = select_identifier_class(data)
        identifier = identifier_class.new

        # Publisher prefix (CAN/CSA-, CAN3-, or CSA).
        # A code with no prefix in the original is a code_only identifier; the
        # flag stops rendering from supplying the default "CSA".
        if data[:publisher_prefix]
          identifier.publisher_prefix = data[:publisher_prefix].to_s
        elsif data[:code]
          identifier.code_only = true
        end

        # Publisher presence flag
        if data[:has_publisher]
          identifier.has_publisher = true
        end

        # Code - with dash-year extraction if needed
        # Skip setting code for Cec identifiers (they use cec_part + no_number instead)
        if data[:code] && !identifier.is_a?(Identifiers::Cec)
          code_value = data[:code].to_s

          # Extract year from code if it ends with -NN (2-digit year) and no separate year parsed
          # Pattern: "C22.1-15" should become code="C22.1", year="2015"
          if !data[:year] && code_value =~ /^(.+)-(\d{2})$/
            # Split code and year
            identifier.number = Components::Code.new(value: $1)
            # Convert 2-digit year to 4-digit
            year_2digit = $2
            identifier.year = "20#{year_2digit}"
            identifier.year_format = "dash"
          else
            identifier.number = Components::Code.new(value: code_value)
          end
        end

        # Special handling for Cec identifiers: map :code to :cec_part
        if identifier.is_a?(Identifiers::Cec) && data[:code] && !identifier.cec_part
          identifier.cec_part = Components::Code.new(value: data[:code].to_s)
        end

        # NO. number handling for Cec identifiers
        if identifier.is_a?(Identifiers::Cec) && data[:no_number]
          identifier.no_number = Components::Code.new(value: data[:no_number].to_s)
        end

        # Series prefix (MH, RV, etc.)
        if data[:series_prefix]
          identifier.series_prefix = data[:series_prefix].to_s
        end

        # Series keyword flag
        if data[:series]
          identifier.series = true
        end

        # Determine year format from markers
        year_format = if data[:dash_format]
                        "dash"
                      elsif data[:colon_format]
                        "colon"
                      else
                        "colon" # default
                      end

        # Year (2-digit needs conversion to 4-digit, 4-digit stays as-is)
        # Only set if not already set by code extraction above
        if data[:year] && !identifier.year
          year_str = data[:year].to_s
          if year_str.length == 2
            # Convert 2-digit year to 4-digit
            # Rule: 00-49 → 2000s, 50-99 → 1900s
            # M prefix also means 1900s (metric/old standards)
            year_int = year_str.to_i
            identifier.year = if data[:year_prefix] && data[:year_prefix].to_s == "M"
                                # M prefix always means 1900s
                                "19#{year_str}"
                              elsif year_int < 50
                                # 00-49 → 2000s
                                "20#{year_str}"
                              else
                                # 50-99 → 1900s
                                "19#{year_str}"
                              end
          else
            # Keep 4-digit years as-is AND mark original format
            identifier.year = year_str
            identifier.original_year_4digit = true
          end
          identifier.year_format = year_format
        end

        # Year prefix (F or M)
        if data[:year_prefix]
          identifier.year_prefix = data[:year_prefix].to_s
          # If year prefix is F, set french flag
          if data[:year_prefix].to_s == "F"
            identifier.french = true
          end
        end

        # French edition flag
        if data[:french]
          identifier.french = true
        end

        # Reaffirmation - supports both 2-digit and 4-digit years
        # Tracks original format via original_reaffirmation_4digit flag
        if data[:reaffirmation_4digit]
          # Original was 4-digit (e.g., "R2019")
          identifier.reaffirmation = data[:reaffirmation_4digit].to_s
          identifier.original_reaffirmation_4digit = true
        elsif data[:reaffirmation_2digit]
          # Original was 2-digit (e.g., "R19"), convert to 4-digit for internal storage
          year_2digit = data[:reaffirmation_2digit].to_s
          year_int = year_2digit.to_i
          identifier.reaffirmation = year_int < 50 ? "20#{year_2digit}" : "19#{year_2digit}"
          identifier.original_reaffirmation_4digit = false
        elsif data[:reaffirmation]
          # Legacy format (Hash or String)
          reaffirm_data = data[:reaffirmation]
          identifier.reaffirmation = if reaffirm_data.is_a?(Hash) && reaffirm_data[:year]
                                       reaffirm_data[:year].to_s
                                     else
                                       reaffirm_data.to_s
                                     end
        end

        # Package portion
        if data[:package_portion]
          identifier.package = data[:package_portion].to_s
        end

        identifier
      end

      def select_identifier_class(data)
        # Priority order (MECE - mutually exclusive, collectively exhaustive):
        # Wrappers first, then type-based classification

        # 1. Check for CAN/CSA- or CAN3- prefix → CanadianAdopted (wrapper)
        if data[:publisher_prefix] &&
            ["CAN/CSA-", "CAN3-"].include?(data[:publisher_prefix].to_s)
          return Identifiers::CanadianAdopted
        end

        # 2. Check for adoption patterns → CsaAdopted (wrapper)
        # Detect adoption_identifier patterns (ISO/IEC/CISPR/CEI adoptions)
        if data[:adoption_number] || data[:iso_type]
          return Identifiers::CsaAdopted
        end

        # 2.5. Check for NO. notation (cec_identifiers parsed with NO. notation)
        if data[:no_notation] && data[:no_number]
          return Identifiers::Cec
        end

        # 3. Check for Series type (series_type means SERIES as primary type from series_identifier rule)
        # NOTE: Do NOT check :series flag here - that's a modifier, not a primary type
        if data[:series_type]
          return Identifiers::Series
        end

        # 3.5. Check for SERIES keyword in combined continuation patterns
        # When SERIES appears in second/third part of combined identifier, it's captured as :series (string)
        if data[:series] && data[:series].to_s == "SERIES"
          return Identifiers::Series
        end

        # 4. Default: Standard
        Identifiers::Standard
      end
    end
  end
end
