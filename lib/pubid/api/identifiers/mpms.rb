# frozen_string_literal: true

module Pubid
  module Api
    module Identifiers
      class Mpms < Base
        attribute :chapter, :string
        attribute :section, :string
        attribute :subsection, :string

        def type_string
          "MPMS"
        end
      end
    end
  end
end
