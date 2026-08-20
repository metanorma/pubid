# frozen_string_literal: true

module Pubid
  module Ietf
    module Identifiers
      # An RFC (Request for Comments), e.g. "RFC 2119".
      class Rfc < Identifier
        include Serialization

        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :rfc,
            stage_code: :published,
            type_code: :rfc,
            abbr: ["RFC"],
            name: "Request for Comments",
            harmonized_stages: [],
          ),
        ].freeze

        def self.type
          { key: :rfc, web: :rfc, title: "Request for Comments", short: "RFC" }
        end
      end
    end
  end
end
