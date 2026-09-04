# frozen_string_literal: true

module Pubid
  module CenCenelec
    class Builder < Pubid::Builder::Base
      def self.build(parsed_data)
        new.build(parsed_data)
      end

      def build(data)
        data = flatten_array(data) if data.is_a?(Array)

        # Store data for access in cast method
        @data = data

        # Check if this is a fragment identifier (AMD + FRAG)
        if data[:fragment_number]
          return build_fragment_identifier(data)
        end

        # Check if this is an adopted identifier (EN ISO, EN IEC, etc.)
        if data[:adopted_string]
          # Special case: ENV can adopt ISO/IEC standards
          if data[:publisher]&.to_s == "ENV"
            return build_env_adopted_identifier(data)
          end

          return build_adopted_identifier(data)
        end

        # Check if this is a standalone amendment/corrigendum (slash separator)
        if has_slash_supplements?(data)
          return build_standalone_supplement(data)
        end

        # Implicit adoption: when an EN has no explicit "IEC" prefix but
        # the number falls in the IEC range (60000-79999), treat it as an
        # adoption of the corresponding IEC standard. The lower ISO-only
        # range (1-59999) is intentionally NOT mapped here — too many
        # existing CEN publications (EN Guide N, EN N as a real CEN-assigned
        # number) would change type. Callers who want explicit adoption
        # can still write "EN ISO 12345".
        # (https://github.com/pubid/pubid/issues/249)
        # Skip when parts are present — they would be lost when we rebuild
        # the identifier from just the base number.
        if data[:publisher]&.to_s == "EN" && !data[:adopted_string] &&
           data[:parts].to_a.empty? &&
           (adopted = build_implicit_adoption(data))
          return adopted
        end

        # Extract supplements before building base identifier (only plus/bundled)
        supplements_data = extract_supplements(data)

        # Determine identifier class using the module's lookup helpers
        identifier = locate_identifier_klass(data).new
        assign_attributes(identifier, data)

        # Wrap with consolidated if supplements present (plus/bundled only)
        if supplements_data.any?
          wrap_with_consolidated(identifier, supplements_data)
        else
          identifier
        end
      end

      private

      def build_fragment_identifier(data)
        # Build base identifier first (without amendment/fragment)
        base_data = data.dup
        base_data.delete(:amendment_number)
        base_data.delete(:fragment_number)

        base = locate_identifier_klass(base_data).new
        assign_attributes(base, base_data)

        # Build Amendment identifier wrapping the base
        amendment = Identifiers::Amendment.new(
          base: base,
          amendment_number: data[:amendment_number].to_s,
        )

        # Build Fragment wrapping the amendment
        Identifiers::Fragment.new(
          base: amendment,
          fragment_number: data[:fragment_number].to_s,
        )
      end

      def locate_identifier_klass(parsed_hash)
        # Special case: Use adopted_european_norm for adopted identifiers
        return Identifiers::AdoptedEuropeanNorm if parsed_hash[:adopted_string]

        # Check if publisher is actually a type code (CWA, HD, ES, CR, ENV act as publisher)
        publisher_str = parsed_hash[:publisher].to_s
        if %w[CWA HD ES CR ENV].include?(publisher_str)
          typed_stage = CenCenelec.locate_stage(publisher_str)
          if (klass = CenCenelec.locate_type(typed_stage.type_code))
            return klass
          end
        end

        # Use type or stage to determine class via the module's registry
        type_or_stage = parsed_hash[:type_with_stage] || parsed_hash[:type] || parsed_hash[:stage] || ""
        typed_stage = CenCenelec.locate_stage(type_or_stage) || CenCenelec::DEFAULT_TYPED_STAGE
        CenCenelec.locate_type(typed_stage.type_code) || Identifiers::EuropeanNorm
      end

      def cast(type, value)
        case type
        when :type_with_stage
          # Lookup from register
          typed_stage = CenCenelec.locate_stage(value.to_s) || CenCenelec::DEFAULT_TYPED_STAGE
          {
            stage: typed_stage.to_stage,
            type: typed_stage.to_type,
            typed_stage: typed_stage,
          }

        when :publisher
          Components::Publisher.new(body: value.to_s)

        when :copublisher
          # Map singular :copublisher to :copublishers array
          { copublishers: [Components::Publisher.new(body: value.to_s)] }

        when :copublishers
          # Handle array of copublishers
          Array(value).map do |v|
            Components::Publisher.new(body: v[:copublisher].to_s)
          end

        when :number
          value.to_s

        when :parts
          # Extract first part, preserve full multi-level part string
          parts_array = Array(value)
          if parts_array.any?
            # Get the part string - it may contain multiple dashes like "5-1-1"
            part_str = parts_array.first[:part].to_s

            # Store the full part value for multi-level parts
            { part: part_str }
          end

        when :part
          value[:part].to_s if value.is_a?(Hash)

        when :year, :date
          # Check if month is present in the data and include it
          month_val = @data[:month]&.to_s
          date_attrs = { year: value.to_s }
          date_attrs[:month] = month_val if month_val && !month_val.empty?
          { date: Components::Date.new(**date_attrs) }

        when :month
          # Month is handled together with year, so skip it here
          nil

        when :type
          Components::Type.new(abbr: value.to_s)

        when :stage
          # Lookup stage in TYPED_STAGES register
          typed_stage = CenCenelec.locate_stage(value.to_s) || CenCenelec::DEFAULT_TYPED_STAGE
          {
            stage: typed_stage.to_stage,
            typed_stage: typed_stage,
          }

        when :edition
          value.to_s

        when :adopted_string
          # Don't cast here, handled in build_adopted_identifier
          nil

        when :supplements
          # Handled separately by extract_supplements
          nil

        else
          value
        end
      end

      def build_adopted_identifier(data)
        # Parse the adopted identifier string with appropriate flavor
        adopted_str = data[:adopted_string]&.to_s&.strip
        return nil unless adopted_str && !adopted_str.empty?

        adopted_id = if adopted_str.start_with?("ISO/IEC") || adopted_str.include?("ISO/IEC")
                       Pubid::Iso.parse(adopted_str)
                     elsif adopted_str.start_with?("ISO")
                       Pubid::Iso.parse(adopted_str)
                     elsif adopted_str.start_with?("IEC")
                       Pubid::Iec.parse(adopted_str)
                     elsif adopted_str.start_with?("CISPR")
                       # CISPR might need specific handling
                       nil
                     end

        # Build publishers array (EN is default for adoptions)
        publishers = []
        publishers << data[:publisher].to_s if data[:publisher]

        # Handle copublishers array
        if data[:copublishers]
          Array(data[:copublishers]).each do |copub|
            publishers << copub[:copublisher].to_s
          end
        elsif data[:copublisher]
          publishers << data[:copublisher].to_s
        end

        publishers = ["EN"] if publishers.empty?

        Identifiers::AdoptedEuropeanNorm.new(
          publisher: publishers,
          adopted_identifier: adopted_id,
        )
      end

      # Implicit adoption by number range. Returns an AdoptedEuropeanNorm
      # wrapping the IEC identifier that the EN number implies, or nil if the
      # number doesn't fall in the IEC range. Limited to IEC range only —
      # see the call site comment for why the ISO range is excluded.
      def build_implicit_adoption(data)
        number = data[:number].to_s
        num_str = number.to_s.strip
        return nil unless num_str.match?(/\A\d{1,6}\z/)

        num = num_str.to_i
        return nil unless (60_000..79_999).cover?(num)

        Identifiers::AdoptedEuropeanNorm.new(
          publisher: ["EN"],
          adopted_identifier: Pubid::Iec.parse("IEC #{num_str}"),
        )
      end

      def build_env_adopted_identifier(data)
        # Parse the adopted identifier string
        adopted_str = data[:adopted_string]&.to_s&.strip
        return nil unless adopted_str && !adopted_str.empty?

        adopted_id = if adopted_str.start_with?("ISO/IEC") || adopted_str.include?("ISO/IEC")
                       Pubid::Iso.parse(adopted_str)
                     elsif adopted_str.start_with?("ISO")
                       Pubid::Iso.parse(adopted_str)
                     elsif adopted_str.start_with?("IEC")
                       Pubid::Iec.parse(adopted_str)
                     end

        Identifiers::EuropeanPrestandard.new(
          adopted_identifier: adopted_id,
        )
      end

      def wrap_with_consolidated(base, supplements_data)
        supplement_ids = supplements_data.map do |supp|
          if supp[:type] == :amendment
            Identifiers::Amendment.new(
              base: base,
              amendment_number: supp[:number],
              amendment_year: supp[:year]&.to_i,
            )
          else
            corr_attrs = {
              base: base,
              corrigendum_number: supp[:number],
              corrigendum_year: supp[:year]&.to_i,
            }
            corr_attrs[:corrigendum_month] = supp[:month] if supp[:month]
            Identifiers::Corrigendum.new(**corr_attrs)
          end
        end

        Identifiers::ConsolidatedIdentifier.new(
          identifiers: [base] + supplement_ids,
        )
      end

      def extract_supplements(data)
        return [] unless data[:supplements]

        supps_array = data[:supplements]
        return [] if supps_array.empty?

        # Only extract supplements with PLUS separator (bundled)
        # Slash-separated supplements are standalone identifiers, not bundled
        supps_array.select do |s|
          supp_data = s.is_a?(Hash) && s[:supplement] ? s[:supplement] : s
          # Only include if it has plus separator
          supp_data[:amd_sep_plus]
        end.map do |s|
          supp_data = s.is_a?(Hash) && s[:supplement] ? s[:supplement] : s

          # Extract year and month if present
          year_val = (supp_data[:amd_year] || supp_data[:year])&.to_s
          month_val = supp_data[:month]&.to_s

          {
            type: supp_data[:amd_number] ? :amendment : :corrigendum,
            number: (supp_data[:amd_number] || supp_data[:cor_number])&.to_s,
            year: year_val,
            month: month_val,
          }
        end
      end

      def has_slash_supplements?(data)
        return false unless data[:supplements]

        supps_array = data[:supplements]
        return false if supps_array.empty?

        # Check if any supplement has slash separator
        supps_array.any? do |s|
          supp_data = s.is_a?(Hash) && s[:supplement] ? s[:supplement] : s
          supp_data[:amd_sep_slash]
        end
      end

      def build_standalone_supplement(data)
        # Build base identifier first (without supplements)
        base_data = data.dup
        base_data.delete(:supplements)
        base = locate_identifier_klass(base_data).new
        assign_attributes(base, base_data)

        # Get the first supplement (slash means only one supplement)
        supp_array = data[:supplements]
        supp_data = supp_array.first
        supp_data = supp_data[:supplement] if supp_data.is_a?(Hash) && supp_data[:supplement]

        # Build appropriate supplement identifier
        if supp_data[:amd_number]
          Identifiers::Amendment.new(
            base: base,
            amendment_number: supp_data[:amd_number].to_s,
            amendment_year: supp_data[:amd_year]&.to_i,
          )
        else
          corr_attrs = {
            base: base,
            corrigendum_number: supp_data[:cor_number]&.to_s,
            corrigendum_year: (supp_data[:cor_year] || supp_data[:year])&.to_i,
          }
          month_val = supp_data[:month]&.to_s
          if month_val && !month_val.empty?
            corr_attrs[:corrigendum_month] =
              month_val
          end
          Identifiers::Corrigendum.new(**corr_attrs)
        end
      end
    end
  end
end
