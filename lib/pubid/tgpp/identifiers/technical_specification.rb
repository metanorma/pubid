# frozen_string_literal: true

module Pubid
  module Tgpp
    module Identifiers
      # Technical Specification identifier type.
      # Format: [3GPP ]TS NN.NNN[suffix][-part…][:<release>][/<version>]
      # Example: TS 23.207:REL-4/2.0.0, or the partial "TS 23.207".
      class TechnicalSpecification < Pubid::Tgpp::Identifier
        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :ts,
            stage_code: :published,
            type_code: :ts,
            abbr: ["TS"],
            name: "Technical Specification",
            harmonized_stages: [],
          ),
        ].freeze

        def self.type
          { key: :ts,
            web: :technical_specification,
            title: "Technical Specification", short: "TS" }
        end

        def type_prefix
          "TS"
        end
      end
    end
  end
end
