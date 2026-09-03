# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Ashrae
    module Identifiers
      # CombinedAddenda identifier for ASHRAE standards and guidelines
      # Represents multiple addendums grouped together
      # Examples:
      # - ASHRAE Addenda c and d to Standard 15-1994
      # - ASHRAE Addenda f and h for Standard 15-2007
      class CombinedAddenda < SupplementIdentifier
        attribute :addendum_codes, :string # Multiple codes like "c and d"
        attribute :connector, :string # "and" or ","

        # See Errata. The whole letter list is the identity here — "Addenda a,
        # b" and "Addenda c, d" of one standard are different documents.
        def mr_supplement_suffix
          ["adds", mr_sanitize(addendum_codes)]
            .compact.reject(&:empty?).join(".")
        end

        TYPED_STAGES = [
          Components::TypedStage.new(
            abbr: ["Addenda", "Combined Addenda"],
            type_code: "combined_addenda",
            stage_code: "published",
          ),
        ].freeze

        def self.type
          { key: :combined_addenda, title: "ASHRAE Combined Addenda",
            short: "Addenda" }
        end

        def copublisher
          base&.copublisher
        end
      end
    end
  end
end
