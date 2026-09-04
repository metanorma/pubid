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

        # The interpreted standard's code must reach the URN. Before this
        # change the flat-parsed form kept its number in the wrapper's own
        # `code_obj` (the builder never built a base), so the URN carried it by
        # accident; now that the number lives on `base` where it belongs, the
        # URN generator has to be pointed at it or the URN silently loses the
        # document number. `code_obj` is a plain attr_accessor, not a lutaml
        # attribute, so overriding it as a method is safe.
        def code_obj
          super || base&.code_obj
        end

        # MR supplement suffix: `int.{year}` — mirrors Corrigendum/Amendment.
        # Without it the MrString renderer slugs an interpretation FLAT off
        # attributes a supplement does not have, instead of recursing into
        # `base`, so every interpretation of every standard collapsed onto
        # "ieee.std.{year}" with no document number at all — and `to_slug` is
        # an output FILENAME.
        def mr_supplement_suffix
          segments = ["int"]
          segments << year.to_s if year
          segments.join(".")
        end

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
