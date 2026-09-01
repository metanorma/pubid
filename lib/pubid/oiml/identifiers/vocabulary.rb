# frozen_string_literal: true

module Pubid
  module Oiml
    module Identifiers
      class Vocabulary < SingleIdentifier
        include CodeNumber

        def type_string
          "V"
        end
      end
    end
  end
end
