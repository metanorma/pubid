# frozen_string_literal: true

module Pubid
  module Itu
    module Identifiers
      # Errata identifier (Err.)
      # Pattern: "ITU-T G.9701 (2014) Err. 1 (07/2016)"
      class Errata < Supplement
        def to_s
          result = base ? base.to_s : "#{publisher}-#{sector}"

          if !base && series
            result += " #{series}"
          end

          result += " Err. #{number}"

          result += render_date_suffix

          result
        end
      end
    end
  end
end
