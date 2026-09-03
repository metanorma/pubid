# frozen_string_literal: true

module Pubid
  module Ashrae
    # Builder class for constructing ASHRAE identifier scheme from parsed data
    # Single Responsibility: Transform parsed data into identifier objects
    class Builder
      attr_reader :identifier_class

      def initialize(identifier_class = Identifier)
        @identifier_class = identifier_class
      end

      # Build a scheme object from parsed data
      # @param parsed [Hash, Array] the parsed identifier data
      # @return [identifier] the constructed scheme object
      def build(parsed)
        # Parslet can return array of hashes - merge them
        parsed_hash = parsed.is_a?(Array) ? merge_parsed_array(parsed) : parsed

        # Check for supplement identifiers first
        if parsed_hash[:errata_keyword]
          return build_errata(parsed_hash)
        elsif parsed_hash[:interpretation_identifier]
          return build_interpretation(parsed_hash[:interpretation_identifier])
        elsif parsed_hash[:combined_addenda]
          return build_combined_addenda(parsed_hash[:combined_addenda])
        elsif parsed_hash[:addenda_package]
          return build_addenda_package(parsed_hash[:addenda_package])
        elsif parsed_hash[:addendum_identifier]
          return build_addendum_from_identifier(parsed_hash[:addendum_identifier])
        elsif parsed_hash[:publisher_addendum]
          return build_publisher_addendum(parsed_hash[:publisher_addendum])
        elsif parsed_hash[:publisher_addendum_copublisher]
          return build_publisher_addendum_copublisher(parsed_hash[:publisher_addendum_copublisher])
        elsif parsed_hash[:publisher_addendum_copublisher_no_type]
          return build_publisher_addendum_copublisher_no_type(parsed_hash[:publisher_addendum_copublisher_no_type])
        elsif parsed_hash[:addendum_no_type]
          return build_addendum_no_type(parsed_hash[:addendum_no_type])
        elsif parsed_hash[:standard_addendum]
          return build_standard_addendum(parsed_hash[:standard_addendum])
        # These two grammar rules had NO dispatch branch, so they fell through
        # to the plain-identifier path below. That path looks for
        # publisher/type/code at the TOP of the hash, finds only the wrapper
        # key, and builds an empty Standard — 123 corpus ids rendered as the
        # bare string "ASHRAE Standard ". Both subtrees are flat and carry
        # exactly the keys #build_addendum_from_identifier already reads.
        elsif parsed_hash[:addendum]
          return build_addendum_from_identifier(parsed_hash[:addendum])
        elsif parsed_hash[:publisher_base_addendum]
          return build_addendum_from_identifier(
            parsed_hash[:publisher_base_addendum],
          )
        end

        # Handle base identifier
        if parsed_hash[:base]
          parsed_hash = parsed_hash[:base]
        end

        attributes = extract_attributes(parsed_hash)
        identifier_class = determine_identifier_class(attributes)
        identifier_class.new(**attributes)
      end

      # Class method to build an identifier from parsed data
      # @param parsed [Hash, Array] the parsed identifier data
      # @return [Identifier] the constructed identifier object
      def self.build(parsed)
        new.build(parsed)
      end

      private

      # Merge an array of parsed hashes into a single hash
      # @param parsed_array [Array<Hash>] array of parsed hashes
      # @return [Hash] merged hash
      def merge_parsed_array(parsed_array)
        parsed_array.inject({}) do |result, hash|
          result.merge(hash)
        end
      end

      # Extract and normalize attributes from parsed data
      # @param parsed [Hash] the parsed data
      # @return [Hash] normalized attributes for identifier
      def extract_attributes(parsed)
        attributes = {}

        # Extract publisher
        if parsed[:publisher]
          attributes[:publisher] =
            extract_value(parsed[:publisher])
        end

        # Extract type - default to "Standard" if not present
        attributes[:type] = extract_value(parsed[:type]) || "Standard"

        # Extract code (from code or code_with_year format)
        if parsed[:code_with_year]
          # code_with_year contains both code and year
          code_year_data = parsed[:code_with_year]
          if code_year_data && code_year_data[:code]
            attributes[:number] =
              extract_value(code_year_data[:code])
          end
          if code_year_data && code_year_data[:year]
            attributes[:year] =
              extract_value(code_year_data[:year])
          end
        elsif parsed[:code]
          attributes[:number] = extract_value(parsed[:code])
        end

        # Extract year if not already extracted from code_with_year
        attributes[:year] ||= extract_value(parsed[:year]) if parsed[:year]

        # Extract suffix (R or P)
        attributes[:suffix] = extract_value(parsed[:suffix]) if parsed[:suffix]

        # Extract reaffirmed year
        if parsed[:reaffirmed]
          attributes[:reaffirmed] =
            extract_value(parsed[:reaffirmed])
        end

        # Extract copublisher
        if parsed[:copublisher]
          attributes[:copublisher] =
            extract_value(parsed[:copublisher])
        end

        attributes
      end

      # Determine which identifier class to use based on attributes
      def determine_identifier_class(attributes)
        type_value = attributes[:type]

        # Use type to determine class
        if type_value == "Guideline"
          Identifiers::Guideline
        elsif type_value == "Standard"
          Identifiers::Standard
        else
          # Default to Standard
          Identifiers::Standard
        end
      end

      # Extract a simple value from parsed data
      # @param value [Object] the value to extract
      # @return [String, nil] the extracted string value
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

      # Build an Errata identifier from parsed errata data
      # @param parsed [Hash] the parsed errata data
      # @return [Identifiers::Errata] the constructed errata identifier
      def build_errata(parsed)
        base_attrs = extract_base_attributes(parsed)
        base_class = determine_identifier_class(base_attrs)
        base = base_class.new(**base_attrs)

        errata_date = extract_errata_date(parsed[:errata_date])

        Identifiers::Errata.new(
          base: base,
          errata_date: errata_date,
        )
      end

      # Build an Interpretation identifier from parsed interpretation data
      # @param parsed [Hash] the parsed interpretation data
      # @return [Identifiers::Interpretation] the constructed interpretation identifier
      def build_interpretation(parsed)
        base_attrs = extract_base_attributes(parsed)
        base_class = determine_identifier_class(base_attrs)
        base = base_class.new(**base_attrs)

        Identifiers::Interpretation.new(
          base: base,
        )
      end

      # Build an Addendum identifier from "Addendum X to Standard" format
      # @param parsed [Hash] the parsed addendum data
      # @return [Identifiers::Addendum] the constructed addendum identifier
      def build_addendum_from_identifier(parsed)
        base_attrs = extract_base_attributes(parsed)
        base_class = determine_identifier_class(base_attrs)
        base = base_class.new(**base_attrs)

        addendum_code = extract_value(parsed[:addendum_code])
        addendum_date = extract_addendum_date(parsed[:addendum_year])

        Identifiers::Addendum.new(
          base: base,
          addendum_code: addendum_code,
          addendum_date: addendum_date,
        )
      end

      # Build an Addendum identifier from "ASHRAE Addendum X to Standard" format
      # @param parsed [Hash] the parsed publisher addendum data
      # @return [Identifiers::Addendum] the constructed addendum identifier
      def build_publisher_addendum(parsed)
        base_attrs = {
          type: extract_value(parsed[:type]),
          number: extract_value(parsed[:code]),
          year: extract_value(parsed[:year]),
        }
        base_class = determine_identifier_class(base_attrs)
        base = base_class.new(**base_attrs)

        addendum_code = extract_value(parsed[:addendum_code])
        addendum_date = extract_addendum_date(parsed[:addendum_year])

        Identifiers::Addendum.new(
          base: base,
          addendum_code: addendum_code,
          addendum_date: addendum_date,
        )
      end

      # Build an Addendum identifier from "ASHRAE Addendum X to ANSI/ASHRAE Standard Y-YYYY" format
      # @param parsed [Hash] the parsed publisher addendum with copublisher data
      # @return [Identifiers::Addendum] the constructed addendum identifier
      def build_publisher_addendum_copublisher(parsed)
        base_attrs = {
          copublisher: extract_value(parsed[:copublisher]),
          type: extract_value(parsed[:type]) || "Standard",
          number: extract_value(parsed[:code]),
          year: extract_value(parsed[:year]),
        }
        base_class = determine_identifier_class(base_attrs)
        base = base_class.new(**base_attrs)

        addendum_code = extract_value(parsed[:addendum_code])
        addendum_date = extract_addendum_date(parsed[:addendum_year])

        Identifiers::Addendum.new(
          base: base,
          addendum_code: addendum_code,
          addendum_date: addendum_date,
        )
      end

      # Build an Addendum identifier from "ANSI/ASHRAE Addendum X to ANSI/ASHRAE 34-2024" (no type) format
      # @param parsed [Hash] the parsed addendum data with code_with_year
      # @return [Identifiers::Addendum] the constructed addendum identifier
      def build_addendum_no_type(parsed)
        # Extract copublisher and code_with_year data
        base_attrs = {}
        if parsed[:copublisher]
          base_attrs[:copublisher] =
            extract_value(parsed[:copublisher])
        end
        base_attrs[:type] = "Standard" # Default to Standard when type is missing

        # Extract code and year from code_with_year
        if parsed[:code_with_year]
          code_year_data = parsed[:code_with_year]
          if code_year_data && code_year_data[:code]
            base_attrs[:number] =
              extract_value(code_year_data[:code])
          end
          if code_year_data && code_year_data[:year]
            base_attrs[:year] =
              extract_value(code_year_data[:year])
          end
        end

        base_class = determine_identifier_class(base_attrs)
        base = base_class.new(**base_attrs)

        addendum_code = extract_value(parsed[:addendum_code])
        addendum_date = extract_addendum_date(parsed[:addendum_year])

        Identifiers::Addendum.new(
          base: base,
          addendum_code: addendum_code,
          addendum_date: addendum_date,
        )
      end

      # Build an Addendum identifier from "ASHRAE Addendum X to ANSI/ASHRAE 62.1-2022" (publisher + copublisher, no type) format
      # @param parsed [Hash] the parsed publisher addendum with copublisher and code_with_year data
      # @return [Identifiers::Addendum] the constructed addendum identifier
      def build_publisher_addendum_copublisher_no_type(parsed)
        # Extract copublisher and code_with_year data
        base_attrs = {}
        if parsed[:copublisher]
          base_attrs[:copublisher] =
            extract_value(parsed[:copublisher])
        end
        base_attrs[:type] = "Standard" # Default to Standard when type is missing

        # Extract code and year from code_with_year
        if parsed[:code_with_year]
          code_year_data = parsed[:code_with_year]
          if code_year_data && code_year_data[:code]
            base_attrs[:number] =
              extract_value(code_year_data[:code])
          end
          if code_year_data && code_year_data[:year]
            base_attrs[:year] =
              extract_value(code_year_data[:year])
          end
        end

        base_class = determine_identifier_class(base_attrs)
        base = base_class.new(**base_attrs)

        addendum_code = extract_value(parsed[:addendum_code])
        addendum_date = extract_addendum_date(parsed[:addendum_year])

        Identifiers::Addendum.new(
          base: base,
          addendum_code: addendum_code,
          addendum_date: addendum_date,
        )
      end

      # Build an Addendum identifier from "Standard X Addendum a" format
      # @param parsed [Hash] the parsed standard addendum data
      # @return [Identifiers::Addendum] the constructed addendum identifier
      def build_standard_addendum(parsed)
        base_attrs = extract_base_attributes(parsed)
        base_class = determine_identifier_class(base_attrs)
        base = base_class.new(**base_attrs)

        addendum_code = extract_value(parsed[:addendum_code])
        addendum_date = extract_addendum_date(parsed[:addendum_year])

        Identifiers::Addendum.new(
          base: base,
          addendum_code: addendum_code,
          addendum_date: addendum_date,
        )
      end

      # Build a CombinedAddenda identifier from "ASHRAE Addenda X and Y to Standard Z-YYYY" format
      # @param parsed [Hash] the parsed combined addenda data
      # @return [Identifiers::CombinedAddenda] the constructed combined addenda identifier
      def build_combined_addenda(parsed)
        # Extract base identifier attributes
        # Handle code_with_year format (used in Formats 5 and 6)
        base_attrs = {}

        if parsed[:code_with_year]
          code_year_data = parsed[:code_with_year]
          if code_year_data && code_year_data[:code]
            base_attrs[:number] =
              extract_value(code_year_data[:code])
          end
          if code_year_data && code_year_data[:year]
            base_attrs[:year] =
              extract_value(code_year_data[:year])
          end
        else
          base_attrs[:type] = extract_value(parsed[:type]) || "Standard"
          base_attrs[:number] = extract_value(parsed[:code])
          base_attrs[:year] = extract_value(parsed[:year])
        end

        if parsed[:copublisher]
          base_attrs[:copublisher] =
            extract_value(parsed[:copublisher])
        end
        if parsed[:publisher]
          base_attrs[:publisher] =
            extract_value(parsed[:publisher])
        end

        base_class = determine_identifier_class(base_attrs)
        base = base_class.new(**base_attrs)

        # Build the addendum_codes string from first code and additional codes
        first_code = extract_value(parsed[:addendum_code])
        additional_codes = parsed[:additional_codes]

        # Handle Format 4: "ASHRAE Addenda to Standard" (no specific codes)
        if first_code.nil? && additional_codes.nil?
          # No codes specified - return nil or empty string for addendum_codes
          addendum_codes_str = nil
        else
          addendum_codes_str = first_code || ""
          if additional_codes
            # additional_codes is an array that can contain:
            # - hashes: {:addendum_code=>"f"}
            # - strings: "a", "b", etc.
            # We need to format them as comma-separated
            code_list = []
            additional_codes.each do |code|
              code_str = if code.is_a?(Hash)
                           # Extract from {:addendum_code=>"f"}
                           extract_value(code[:addendum_code])
                         else
                           # Direct string value
                           extract_value(code)
                         end
              code_list << code_str if code_str && code_str != "and"
            end
            # Join with commas
            addendum_codes_str += ", #{code_list.join(', ')}" unless code_list.empty?
          end
        end

        Identifiers::CombinedAddenda.new(
          base: base,
          addendum_codes: addendum_codes_str,
        )
      end

      # Build an AddendaPackage identifier from "ASHRAE Standard X-YYYY: Addenda Supplement Package" format
      # @param parsed [Hash] the parsed addenda package data
      # @return [Identifiers::AddendaPackage] the constructed addenda package identifier
      def build_addenda_package(parsed)
        base_attrs = extract_base_attributes(parsed)
        base_class = determine_identifier_class(base_attrs)
        base = base_class.new(**base_attrs)

        package_description = extract_value(parsed[:package_description])

        Identifiers::AddendaPackage.new(
          base: base,
          package_description: package_description,
        )
      end

      # Extract base identifier attributes from parsed data
      # @param parsed [Hash] the parsed data
      # @return [Hash] attributes for base identifier
      def extract_base_attributes(parsed)
        # Unwrap the `:base` subtree the supplement grammars nest the base
        # document under. Builder#build does this for the plain-identifier
        # path, but the five supplement builders that call this method all
        # passed the WHOLE parse hash — so every lookup below missed and the
        # base was built with nothing. 318 Errata rendered as the identical
        # string "ASHRAE Standard  Errata"; doing it here fixes all five call
        # sites at once, rather than repeating the unwrap in each.
        parsed = parsed[:base] if parsed.is_a?(Hash) && parsed[:base]

        attributes = {}

        if parsed[:publisher]
          attributes[:publisher] =
            extract_value(parsed[:publisher])
        end
        if parsed[:copublisher]
          attributes[:copublisher] =
            extract_value(parsed[:copublisher])
        end
        # Default to "Standard" if type is not present
        attributes[:type] = extract_value(parsed[:type]) || "Standard"

        # Handle code_with_year format
        if parsed[:code_with_year]
          code_year_data = parsed[:code_with_year]
          if code_year_data && code_year_data[:code]
            attributes[:number] =
              extract_value(code_year_data[:code])
          end
          if code_year_data && code_year_data[:year]
            attributes[:year] =
              extract_value(code_year_data[:year])
          end
        else
          attributes[:number] = extract_value(parsed[:code]) if parsed[:code]
          attributes[:year] = extract_value(parsed[:year]) if parsed[:year]
        end

        attributes[:suffix] = extract_value(parsed[:suffix]) if parsed[:suffix]
        if parsed[:reaffirmed]
          attributes[:reaffirmed] =
            extract_value(parsed[:reaffirmed])
        end

        attributes
      end

      # Extract errata date from parsed errata_date data
      # @param errata_date [Hash] the parsed errata_date hash
      # @return [String, nil] the formatted errata date string
      def extract_errata_date(errata_date)
        return nil unless errata_date

        # errata_date contains { month_name: "...", errata_year: "..." }
        # We need to format this as "Month Day, Year"
        extract_value(errata_date[:month_name])
        extract_value(errata_date[:errata_year])
        # Note: day is captured as digit.repeat(1,2) but not named in the parser
        # We'll need to reconstruct from the raw string or enhance parser
        nil # For now, return nil - parser enhancement needed
      end

      # Extract addendum date from parsed addendum_year data
      # @param addendum_year [String, Hash] the parsed addendum year data
      # @return [String, nil] the formatted addendum date string
      def extract_addendum_date(addendum_year)
        return nil unless addendum_year

        # Date extraction would require more detailed parser
        nil
      end
    end
  end
end
