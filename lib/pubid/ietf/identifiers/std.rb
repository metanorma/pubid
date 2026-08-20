# frozen_string_literal: true

module Pubid
  module Ietf
    module Identifiers
      # An STD (Internet Standard) sub-series id, e.g. "STD 66".
      class Std < Identifier
        include Serialization

        # The series token is derived from the class, not stored:
        # `_type` already encodes it, so serializing `series` would
        # duplicate the type in every index row.
        SERIES = "STD"

        def series
          SERIES
        end

        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :std,
            stage_code: :published,
            type_code: :std,
            abbr: ["STD"],
            name: "Internet Standard",
            harmonized_stages: [],
          ),
        ].freeze

        def self.type
          { key: :std, web: :std, title: "Internet Standard", short: "STD" }
        end
      end
    end
  end
end
