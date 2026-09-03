# frozen_string_literal: true

module Pubid
  module Astm
    module Identifiers
      class Standard < Base
        include CodeNumber

        attribute :sub_year, :string        # a, b, c
        attribute :reapproval, :string      # (2023)

        attribute :edition, :string # e1

        # A reapproved edition is a distinct document — "ASTM C1870-18(2024)"
        # and "ASTM C1870-18" have different hashes — so the marker has to
        # reach the slug as well as `==`, or they share a filename.
        def mr_number_with_part
          mr_join(super, (reapproval ? "r#{reapproval}" : nil))
        end
      end
    end
  end
end
