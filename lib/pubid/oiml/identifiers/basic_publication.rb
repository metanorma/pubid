# frozen_string_literal: true

module Pubid
  module Oiml
    module Identifiers
      class BasicPublication < SingleIdentifier
        include CodeNumber

        def type_string
          "B"
        end
      end
    end
  end
end
