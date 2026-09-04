# frozen_string_literal: true

module Pubid
  module Idf
    class UrnGenerator < Pubid::UrnGenerator::Base
      def urn_type
        return nil unless identifier.type

        identifier.type.abbr.to_s.downcase
      end

      def generate
        parts = ["urn", "idf"]
        parts << urn_number if urn_number
        parts << urn_part if urn_part
        parts << urn_subpart if urn_subpart
        parts << urn_year if urn_year
        parts << urn_edition if urn_edition
        parts << urn_type if urn_type

        if identifier.publisher
          parts[1] = identifier.publisher.render(context: URN_CONTEXT)
        end

        if identifier.copublishers&.any?
          copubs = identifier.copublishers.map { |cp| cp.render(context: URN_CONTEXT) }
          parts[1] = "#{parts[1]}-#{copubs.join('-')}"
        end

        if identifier.languages&.any?
          parts << identifier.languages.map(&:code).join(",")
        end

        if identifier.is_a?(SupplementIdentifier)
          if identifier.typed_stage
            supp_type = identifier.typed_stage.type_code.to_s
            parts << supp_type if supp_type
          end

          if identifier.number
            parts << identifier.number
          end
        end

        parts.join(":")
      end
    end
  end
end
