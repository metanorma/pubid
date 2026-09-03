# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Ashrae
    module Identifiers
      # Interpretation identifier for ASHRAE standards
      # Represents a collection of interpretations for a base standard
      # Examples:
      # - Interpretations for Standard 15.2-2022
      # - Interpretations for Standard 52.1-1992
      class Interpretation < SupplementIdentifier
        # Mirrors its four sibling supplement types: without it
        # Renderers::MrString slugs the interpretation FLAT off attributes it
        # does not have, instead of recursing into `base`.
        #
        # Currently unreachable — an "Interpretations for …" reference never
        # gets here, because an earlier grammar alternative claims it and the
        # builder produces a plain Standard (pre-existing; pinned in
        # spec/pubid/ashrae/root_number_spec.rb, hand-off
        # ashrae-interpretation-collapses-onto-base). Added anyway so that
        # fixing the dispatch does not silently ship malformed filenames.
        def mr_supplement_suffix
          "interp"
        end

        TYPED_STAGES = [
          Components::TypedStage.new(
            abbr: ["Interpretations"],
            type_code: "interpretation",
            stage_code: "published",
          ),
        ].freeze

        def self.type
          { key: :interpretation, title: "ASHRAE Interpretations",
            short: "Interpretations" }
        end
      end
    end
  end
end
