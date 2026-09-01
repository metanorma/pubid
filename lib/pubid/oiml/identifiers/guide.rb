# frozen_string_literal: true

module Pubid
  module Oiml
    module Identifiers
      class Guide < SingleIdentifier
        include CodeNumber

        def type_string
          "G"
        end
      end
    end
  end
end
