# frozen_string_literal: true

module Pubid
  module Oiml
    module Identifiers
      class SeminarReport < SingleIdentifier
        include CodeNumber

        def type_string
          "S"
        end
      end
    end
  end
end
