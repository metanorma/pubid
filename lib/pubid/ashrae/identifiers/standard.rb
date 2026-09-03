# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Ashrae
    module Identifiers
      # ASHRAE Standard identifier
      # Example: ASHRAE Standard 15-2024, ASHRAE Standard 90.1-2022
      class Standard < SingleIdentifier
        # The relaton index key. Declared on the LEAF, not on the shared
        # Identifier that SupplementIdentifier also inherits — see base.rb.
        attribute :number, :string
        attribute :type, :string, default: "Standard"

        TYPED_STAGES = [
          Components::TypedStage.new(
            abbr: ["Standard", "ASHRAE"],
            type_code: "standard",
            stage_code: "published",
          ),
          Components::TypedStage.new(
            abbr: ["P"],
            type_code: "standard",
            stage_code: "proposed",
            project_status: true,
          ),
          Components::TypedStage.new(
            abbr: ["R"],
            type_code: "standard",
            stage_code: "revision",
          ),
        ].freeze

        def self.type
          { key: :standard, title: "ASHRAE Standard", short: "Standard" }
        end
      end
    end
  end
end
