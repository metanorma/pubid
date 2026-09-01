# frozen_string_literal: true

module Pubid
  module Oiml
    module Identifiers
      class Recommendation < SingleIdentifier
        include CodeNumber

        def type_string
          "R"
        end
      end
    end
  end
end
