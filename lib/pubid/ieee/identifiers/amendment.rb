# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # Amendment identifier for IEEE standards
      # Represents additions/changes to a published standard
      # Example: IEEE Std 802.3-2018/Amd 4-2020
      class Amendment < SupplementIdentifier
        # The amendment's own ordinal (`number`) and `year` — uniform names,
        # not `amd_number`/`amd_year`. `number` is a plain string redefining the
        # inherited Components::Code (leaf-safe, like the standards); `year` is
        # the inherited base :string. `root.number` still returns the *base*
        # document number, so the index key is unaffected. Mirrors Corrigendum.
        attribute :number, :string
        # `year` inherited from the base.

        # TYPED_STAGES for amendment
        # Amendment uses "Amd" abbreviation
        TYPED_STAGES = [
          Components::TypedStage.new(
            abbr: ["Amd"],
            type_code: "amendment",
            stage_code: "published",
          ),
        ].freeze

        # MR supplement suffix: `amd.{number}.{year}` (e.g. "/amd.4.2020").
        # The MrString renderer recurses into `base` and appends this so the
        # full IEEE amendment round-trips losslessly (mirrors Corrigendum).
        def mr_supplement_suffix
          segments = ["amd"]
          segments << number.to_s if number
          segments << year.to_s if year
          segments.join(".")
        end
      end
    end
  end
end
