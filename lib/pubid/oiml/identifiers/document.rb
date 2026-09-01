# frozen_string_literal: true

module Pubid
  module Oiml
    module Identifiers
      class Document < SingleIdentifier
        include CodeNumber

        def type_string
          "D"
        end
      end
    end
  end
end
