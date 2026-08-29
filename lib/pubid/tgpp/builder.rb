# frozen_string_literal: true

module Pubid
  module Tgpp
    class Builder
      def self.build(parsed_data)
        new.build(parsed_data)
      end

      def build(data)
        identifier_class(data[:type]).new(
          number: data[:number].to_s,
          suffix: data[:suffix]&.to_s,
          parts: extract_part_strings(data[:parts]),
          release: data[:release]&.to_s,
          version: data[:version]&.to_s,
        )
      end

      private

      def identifier_class(type)
        if type.to_s == "TR"
          Identifiers::TechnicalReport
        else
          Identifiers::TechnicalSpecification
        end
      end

      # parts_data is an array of `{ part: "1" }` hashes (or a single hash for a
      # one-level part); return the part numbers as strings.
      def extract_part_strings(parts_data)
        case parts_data
        when Array then parts_data.filter_map { |h| h[:part]&.to_s }
        when Hash then [parts_data[:part]&.to_s].compact
        else []
        end
      end
    end
  end
end
