# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # Conformance identifier for IEEE standards
      # Represents conformance test documents
      # Example: IEEE Std 802.16/Conformance01-2003
      class ConformanceIdentifier < SupplementIdentifier
        # Uniform `number` (the conformance ordinal) + inherited `year`, not
        # `conf_number`/`conf_year`. `number` is a plain string redefining the
        # inherited Components::Code (leaf-safe). `root.number` still returns the
        # base document number.
        attribute :number, :string
        # `year` inherited from the base.

        # TYPED_STAGES for conformance
        # Conformance uses "Conformance" abbreviation
        TYPED_STAGES = [
          Components::TypedStage.new(
            abbr: ["Conformance"],
            type_code: "conformance",
            stage_code: "published",
          ),
        ].freeze
      end
    end
  end
end
