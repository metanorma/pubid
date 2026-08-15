# frozen_string_literal: true

module Pubid
  module Itu
    module Identifiers
      # Errata identifier (Err.)
      # Pattern: "ITU-T G.9701 (2014) Err. 1 (07/2016)"
      class Errata < Supplement
        def to_s
          render_supplement("Err.")
        end
      end
    end
  end
end
