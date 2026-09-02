# frozen_string_literal: true

module Pubid
  module Amca
    # Builder class for constructing ACMA identifier scheme from parsed data
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

        # Handle base identifier wrapper
        if parsed_hash[:base]
          parsed_hash = parsed_hash[:base]
        end

        # Check for publication identifier (must come before standard check)
        if parsed_hash[:publication] || parsed_hash[:publication_keyword] || parsed_hash[:revision]
          return build_publication(parsed_hash[:publication] || parsed_hash)
        end

        # Check for interpretation identifier
        if parsed_hash[:interpretation] || parsed_hash[:interpretation_code] || parsed_hash[:interp_keyword]
          return build_interpretation(parsed_hash[:interpretation] || parsed_hash)
        end

        # Handle standard identifier
        if parsed_hash[:standard]
          return build_standard(parsed_hash[:standard])
        end

        # Default: extract attributes and create identifier
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
      # @return [Hash] normalized attributes for Identifier
      def extract_attributes(parsed)
        attributes = {}

        # Extract copublisher
        if parsed[:copublisher]
          attributes[:copublisher] =
            extract_value(parsed[:copublisher])
        end

        # Extract code
        if parsed[:code_with_year]
          code_year_data = parsed[:code_with_year]
          if code_year_data && code_year_data[:code]
            attributes[:code] =
              extract_value(code_year_data[:code])
          end
          if code_year_data && code_year_data[:year]
            attributes[:year] =
              extract_value(code_year_data[:year])
          end
        elsif parsed[:code]
          attributes[:code] = extract_value(parsed[:code])
        end

        # Extract year if not already extracted from code_with_year
        attributes[:year] ||= extract_value(parsed[:year]) if parsed[:year]

        # Extract suffix
        attributes[:suffix] = extract_value(parsed[:suffix]) if parsed[:suffix]

        # Extract reaffirmed year (R2008, R2010, etc.)
        if parsed[:reaffirmed]
          attributes[:reaffirmed] =
            extract_value(parsed[:reaffirmed])
        end

        attributes
      end

      # Determine which identifier class to use based on attributes
      # @param attributes [Hash] the extracted attributes
      # @return [Class] the identifier class
      def determine_identifier_class(_attributes)
        # Default to Standard for ACMA
        Identifiers::Standard
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

      # Build an Interpretation identifier from parsed interpretation data
      # @param parsed [Hash] the parsed interpretation data
      # @return [Identifiers::Interpretation] the constructed interpretation identifier
      def build_interpretation(parsed)
        # "AMCA 511 Interp" with no code/year is the standard itself
        unless parsed[:interpretation_code] || parsed[:interpretation_year]
          return build_standard(parsed)
        end
        attributes = extract_attributes(parsed)

        # Extract interpretation code (JW, KB, RG, AW, AH, or number)
        if parsed[:interpretation_code]
          attributes[:interpretation_code] =
            extract_value(parsed[:interpretation_code])
        end

        # Interpretations may not have a year
        attributes[:year] ||= extract_value(parsed[:interpretation_year]) if parsed[:interpretation_year]

        Identifiers::Interpretation.new(**attributes)
      end

      # Build a Publication identifier from parsed publication data
      # @param parsed [Hash] the parsed publication data
      # @return [Identifiers::Publication] the constructed publication identifier
      def build_publication(parsed)
        attributes = extract_attributes(parsed)

        # Extract revision (Rev. 01-23)
        if parsed[:revision]
          revision_data = parsed[:revision]
          if revision_data && revision_data[:revision_year]
            attributes[:revision] =
              extract_value(revision_data[:revision_year])
          end
        end

        Identifiers::Publication.new(**attributes)
      end

      # Build a Standard identifier from parsed standard data
      # @param parsed [Hash] the parsed standard data
      # @return [Identifiers::Standard] the constructed standard identifier
      def build_standard(parsed)
        attributes = extract_attributes(parsed)
        Identifiers::Standard.new(**attributes)
      end
    end
  end
end
