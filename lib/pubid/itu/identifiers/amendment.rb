# frozen_string_literal: true

module Pubid
  module Itu
    module Identifiers
      # Amendment identifier (Amd)
      # Pattern: "ITU-T G.989 Amd. 1", "ITU-T G.780/Y.1351 Amd. 1 (2004)"
      class Amendment < Supplement
        # "Amd." with the period, matching ITU's own rendering and the sibling
        # supplement types (Cor./Err./Suppl./Add.). The parser accepts both
        # spellings (see Parser#supplement_type), so the period-less input form
        # still round-trips through parse — it just normalizes here.
        def to_s
          render_supplement("Amd.")
        end
      end
    end
  end
end
