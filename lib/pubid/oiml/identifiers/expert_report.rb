# frozen_string_literal: true

module Pubid
  module Oiml
    module Identifiers
      class ExpertReport < SingleIdentifier
        include CodeNumber

        def type_string
          "E"
        end
      end
    end
  end
end
