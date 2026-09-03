# frozen_string_literal: true

module Pubid
  module Astm
    class Builder
      def build(parsed_hash)
        # Determine identifier class based on type
        identifier_class = determine_identifier_class(parsed_hash)
        identifier = identifier_class.new

        # The code is stored as flat index columns on every concrete class (see
        # Identifiers::CodeNumber) — `number` is what relaton-index keys on —
        # so the Code built below is unpacked rather than assigned.
        if parsed_hash[:letter] || parsed_hash[:number]
          code = build_code(parsed_hash)
          identifier.letter = code.letter
          identifier.number = code.number
          identifier.suffix = code.suffix
          identifier.subseries = code.subseries
          identifier.dual_m = code.dual_m || false
        end

        # Set publisher
        # Special case: handle "ISO/ASTMTR" type - split into publisher "ISO/ASTM" and type "TR"
        if parsed_hash[:type]&.to_s == "ISO/ASTMTR"
          identifier.publisher = "ISO/ASTM"
        else
          identifier.publisher = parsed_hash[:publisher].to_s if parsed_hash[:publisher]
          identifier.publisher ||= "ASTM"
        end

        # Set year (convert 2-digit to 4-digit)
        if parsed_hash[:year]
          identifier.year = convert_year(parsed_hash[:year].to_s)
        end

        # Set format suffix with dash prefix
        if parsed_hash[:format_suffix]
          identifier.format_suffix = "-#{parsed_hash[:format_suffix]}"
        end

        # Type-specific attributes
        build_type_specific_attributes(identifier, parsed_hash)

        identifier
      end

      private

      def determine_identifier_class(parsed_hash)
        type = parsed_hash[:type]&.to_s

        # Check for ISO/ASTM dual-published standards (5xxxx series)
        # These are digit-only identifiers starting with "5"
        # No explicit type, check if it's a digit-only number
        if (type.nil? || type.empty?) && parsed_hash[:number] && !parsed_hash[:letter]
          number_str = parsed_hash[:number].to_s
          # If starts with "5", likely ISO/ASTM dual-published
          if number_str.start_with?("5")
            return Identifiers::IsoDualPublished
          end

          # Other digit-only numbers are still Standard
          return Identifiers::Standard
        end

        case type
        when "RR"
          Identifiers::ResearchReport
        when "MNL"
          Identifiers::Manual
        when "MONO"
          Identifiers::Monograph
        when "DS"
          Identifiers::DataSeries
        when "WK"
          Identifiers::WorkInProgress
        when "ADJ"
          Identifiers::Adjunct
        when "TR"
          Identifiers::TechnicalReport
        when "ISO/ASTMTR" # Handle ISO/ASTM Technical Report
          Identifiers::TechnicalReport
        else
          # Default to Standard (A-G prefix)
          Identifiers::Standard
        end
      end

      def build_code(parsed_hash)
        code = Components::Code.new
        # Special case: for "TR" type with "ISO/ASTM" publisher, don't set letter
        # as the "TR" is part of the type/identifier format, not the code letter
        if parsed_hash[:letter] && !(parsed_hash[:type]&.to_s == "TR" && parsed_hash[:publisher]&.to_s&.start_with?("ISO/ASTM"))
          code.letter = parsed_hash[:letter].to_s
        end
        code.number = parsed_hash[:number].to_s if parsed_hash[:number]
        code.suffix = parsed_hash[:suffix].to_s if parsed_hash[:suffix]
        code.subseries = parsed_hash[:subseries].to_s if parsed_hash[:subseries]
        code.dual_m = true if parsed_hash[:dual_m]
        code
      end

      def build_type_specific_attributes(identifier, parsed_hash)
        # Research Report
        if identifier.is_a?(Identifiers::ResearchReport) && parsed_hash[:committee]
          identifier.committee = parsed_hash[:committee].to_s
        end

        # Manual
        if identifier.is_a?(Identifiers::Manual)
          identifier.edition = parsed_hash[:edition].to_s if parsed_hash[:edition]
          identifier.supplement = true if parsed_hash[:supplement]
          identifier.tp_designation = parsed_hash[:tp_designation].to_s if parsed_hash[:tp_designation]
        end

        # Monograph
        if identifier.is_a?(Identifiers::Monograph) && parsed_hash[:edition]
          identifier.edition = parsed_hash[:edition].to_s
        end

        # Data Series
        if identifier.is_a?(Identifiers::DataSeries) && parsed_hash[:hol_suffix]
          identifier.hol_suffix = true
        end

        # Adjunct
        if identifier.is_a?(Identifiers::Adjunct)
          identifier.number = parsed_hash[:designation].to_s if parsed_hash[:designation]
          identifier.ea_suffix = true if parsed_hash[:ea_suffix]
          identifier.dvd_suffix = true if parsed_hash[:dvd_suffix]
        end

        # Standard-specific
        if identifier.is_a?(Identifiers::Standard)
          identifier.sub_year = parsed_hash[:sub_year].to_s if parsed_hash[:sub_year]
          identifier.reapproval = parsed_hash[:reapproval].to_s if parsed_hash[:reapproval]
          # Handle edition - can be from :edition_number (e1) or :edition (1ST)
          # The parsed hash can have nested structure: {:edition=>{:edition_number=>"1"}} or {:edition=>"1ST"}
          edition_data = parsed_hash[:edition]
          if edition_data
            if edition_data.is_a?(Hash)
              # e-notation: {:edition_number=>"1"}
              identifier.edition = edition_data[:edition_number].to_s if edition_data[:edition_number]
            else
              # Ordinal notation: "1ST"
              identifier.edition = edition_data.to_s
            end
          end
        end
      end

      def convert_year(year_str)
        return year_str if year_str.length == 4

        # 2-digit year conversion
        year_int = year_str.to_i
        if year_int <= 24
          "20#{year_str}"
        else
          "19#{year_str}"
        end
      end
    end
  end
end
