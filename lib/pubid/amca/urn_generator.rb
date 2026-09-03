# frozen_string_literal: true

module Pubid
  module Amca
    class UrnGenerator < Pubid::UrnGenerator::Base
      def urn_number
        return nil unless identifier.number

        identifier.number.to_s
      end

      def urn_year
        return nil unless identifier.year

        identifier.year.to_s
      end

      def urn_suffix
        identifier.suffix&.to_s&.downcase
      end

      def urn_reaffirmed
        "reaff.#{identifier.reaffirmed}" if identifier.reaffirmed
      end

      def urn_copublisher
        "copub.#{identifier.copublisher.to_s.downcase}" if identifier.copublisher
      end

      def urn_type
        (identifier.class.respond_to?(:type) ? identifier.class.type : nil)
          &.to_s&.downcase
      end

      def generate
        parts = ["urn", "amca"]
        parts << urn_number if urn_number
        parts << urn_year if urn_year
        parts << urn_suffix if urn_suffix
        parts << urn_reaffirmed if urn_reaffirmed
        parts << urn_copublisher if urn_copublisher

        parts[1] = identifier.publisher.to_s.downcase if identifier.publisher

        parts << urn_type if urn_type

        parts.join(":")
      end
    end
  end
end
