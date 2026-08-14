# frozen_string_literal: true

module Pubid
  module Itu
    module Identifiers
      # Addendum identifier (Add.)
      # Pattern: "ITU-T I.363 (1993) Add. 1 (11/1993)"
      class Addendum < Supplement
        def to_s
          render_supplement("Add.")
        end
      end
    end
  end
end
