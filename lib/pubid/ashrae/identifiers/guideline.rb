# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Ashrae
    module Identifiers
      # ASHRAE Guideline identifier
      # Example: ASHRAE Guideline 0-2019, ASHRAE Guideline 1.5
      class Guideline < SingleIdentifier
        # The relaton index key. Declared on the LEAF, not on the shared
        # Identifier that SupplementIdentifier also inherits — see base.rb.
        attribute :number, :string
        attribute :type, :string, default: "Guideline"

        TYPED_STAGES = [
          Components::TypedStage.new(
            abbr: ["Guideline", "ASHRAE"],
            type_code: "guideline",
            stage_code: "published",
          ),
          Components::TypedStage.new(
            abbr: ["P"],
            type_code: "guideline",
            stage_code: "proposed",
            project_status: true,
          ),
          Components::TypedStage.new(
            abbr: ["R"],
            type_code: "guideline",
            stage_code: "revision",
          ),
        ].freeze

        def self.type
          { key: :guideline, title: "ASHRAE Guideline", short: "Guideline" }
        end
      end
    end
  end
end
