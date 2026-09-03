# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Ashrae
    module Identifiers
      # Addendum identifier for ASHRAE standards and guidelines
      # Examples:
      # - ASHRAE Addendum a to Standard 15-2001
      # - ASHRAE Addendum a to Guideline 1.4-2019
      # - ANSI/ASHRAE Addendum a to ANSI/ASHRAE Standard 15-2019
      # - ASHRAE Standard 15-2013 Addendum a
      class Addendum < SupplementIdentifier
        attribute :addendum_code, :string  # a, b, c, ..., aa, ab, ..., ba, etc.
        attribute :addendum_date, :string  # Optional date (January 22, 2019)

        # See Errata: the renderer must recurse into `base`. The addendum
        # letter is what distinguishes addendum a from addendum b of one
        # standard, so it belongs in the slug as well as in `==`.
        def mr_supplement_suffix
          ["add", addendum_code&.to_s&.downcase]
            .compact.reject(&:empty?).join(".")
        end

        TYPED_STAGES = [
          Components::TypedStage.new(
            abbr: ["Addendum", "Addenda"],
            type_code: "addendum",
            stage_code: "published",
          ),
        ].freeze

        def self.type
          { key: :addendum, title: "ASHRAE Addendum", short: "Addendum" }
        end

        def copublisher
          base&.copublisher
        end
      end
    end
  end
end
