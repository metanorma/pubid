# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # Interpretation identifier for IEEE standards
      # Represents an interpretation sheet or clarification
      # Example: IEEE Std 1076/INT-1991, IEEE Std 1003.1-1988/INT
      class InterpretationIdentifier < SupplementIdentifier
        # Uniform `year` (the interpretation year), not `int_year` — inherited
        # from the base, so no attribute is declared here.

        # TYPED_STAGES for interpretation
        # Interpretation uses "INT" abbreviation
        TYPED_STAGES = [
          Components::TypedStage.new(
            abbr: ["INT"],
            type_code: "interpretation",
            stage_code: "published",
          ),
        ].freeze
      end
    end
  end
end
