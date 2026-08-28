# frozen_string_literal: true

module Pubid
  module CenCenelec
    module Identifiers
      # AdoptedEuropeanNorm wraps ISO/IEC identifiers
      # Example: "EN ISO 8601:2019" where ISO 8601:2019 is an ISO identifier object
      class AdoptedEuropeanNorm < EuropeanNorm
        attribute :adopted_identifier, ::Pubid::Identifier, polymorphic: true # ISO/IEC/IEEE object

        # Override self.type to return nil so that AdoptedEuropeanNorm is NOT
        # registered as a type in CenCenelec.identifier_types. The class is a
        # polymorphic wrapper that wraps an adopted ISO/IEC identifier under an
        # EN publisher; it is constructed explicitly by Builder#build_adopted_identifier,
        # not selected via type-code lookup. Returning nil here prevents
        # identifier_types auto-discovery from shadowing EuropeanNorm (which
        # also reports :en) in CenCenelec.locate_type(:en).
        def self.type
          nil
        end

        # Delegate common methods to adopted identifier
        def number
          adopted_identifier&.number
        end

        def year
          adopted_identifier&.year if adopted_identifier&.methods&.include?(:year)
        end

        def date
          adopted_identifier&.date if adopted_identifier&.methods&.include?(:date)
        end

        def parts
          adopted_identifier&.parts if adopted_identifier&.methods&.include?(:parts)
        end

        def part
          adopted_identifier&.part if adopted_identifier&.methods&.include?(:part)
        end
      end
    end
  end
end
