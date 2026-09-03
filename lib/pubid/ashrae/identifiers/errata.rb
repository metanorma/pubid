# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Ashrae
    module Identifiers
      # Errata identifier for ASHRAE standards and guidelines
      # Represents corrections/errata for a base standard
      # Examples:
      # - ASHRAE Guideline 0-2005 Errata (September 28, 2011)
      # - ANSI/ASHRAE Standard 62.1-2004 Errata (May 4, 2007)
      class Errata < SupplementIdentifier
        attribute :errata_date, :string

        # Make Renderers::MrString recurse into `base` instead of slugging the
        # supplement flat off attributes it does not have. Without it every
        # erratum of every standard shared one filename, and `to_slug` is what
        # consumers use as an output filename.
        def mr_supplement_suffix
          ["errata", mr_sanitize(errata_date)]
            .compact.reject(&:empty?).join(".")
        end

        TYPED_STAGES = [
          Components::TypedStage.new(
            abbr: ["Errata"],
            type_code: "errata",
            stage_code: "published",
          ),
        ].freeze

        def self.type
          { key: :errata, title: "ASHRAE Errata", short: "Errata" }
        end
      end
    end
  end
end
