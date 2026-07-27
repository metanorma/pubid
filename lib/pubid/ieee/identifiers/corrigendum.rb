# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # Corrigendum identifier for IEEE standards
      # Represents corrections to published standards
      # Example: IEEE Std 535-2013/Cor. 1-2017
      class Corrigendum < SupplementIdentifier
        # The corrigendum's own ordinal (`number`) and `year` — uniform names,
        # not `cor_number`/`cor_year`. `number` is a plain string redefining the
        # inherited Components::Code (leaf-safe, like the standards); `year` is
        # the inherited base :string. `root.number` still returns the *base*
        # document number, so the index key is unaffected.
        attribute :number, :string
        # `year` inherited from the base.

        # TYPED_STAGES for corrigendum
        # Corrigendum uses "Cor" abbreviation
        TYPED_STAGES = [
          Components::TypedStage.new(
            abbr: ["Cor"],
            type_code: "corrigendum",
            stage_code: "published",
          ),
        ].freeze

        # MR supplement suffix: `cor.{number}.{year}` (e.g. "/cor.1.2017").
        # The MrString renderer recurses into `base` and appends this so the
        # full IEEE corrigendum round-trips losslessly (issue #142).
        def mr_supplement_suffix
          segments = ["cor"]
          segments << number.to_s if number
          segments << year.to_s if year
          segments.join(".")
        end
      end
    end
  end
end
