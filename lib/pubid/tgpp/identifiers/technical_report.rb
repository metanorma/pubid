# frozen_string_literal: true

module Pubid
  module Tgpp
    module Identifiers
      # Technical Report identifier type.
      # Format: [3GPP ]TR NN.NNN[suffix][-part…][:<release>][/<version>]
      # Example: TR 00.01U:UMTS/3.0.0, or the partial "TR 00.01U".
      class TechnicalReport < Pubid::Tgpp::Identifier
        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :tr,
            stage_code: :published,
            type_code: :tr,
            abbr: ["TR"],
            name: "Technical Report",
            harmonized_stages: [],
          ),
        ].freeze

        def self.type
          { key: :tr,
            web: :technical_report, title: "Technical Report", short: "TR" }
        end

        def type_prefix
          "TR"
        end
      end
    end
  end
end
