# frozen_string_literal: true

module Pubid
  module Astm
    module Identifiers
      class Manual < Base
        include CodeNumber

        attribute :edition, :string          # 9TH, 2ND
        attribute :supplement, :boolean      # -SUP-
        attribute :tp_designation, :string   # TP for technical publications

        # Both markers distinguish real documents that share a number —
        # "ASTM MNL15-EB" vs "ASTM MNLTP15-EB", and "ASTM MNL20-2ND-EB" vs
        # "ASTM MNL20-2ND-SUP-EB" — so both must reach the slug, not just the
        # hash.
        def mr_number_with_part
          mr_join(tp_designation&.downcase, super, (supplement ? "sup" : nil))
        end
      end
    end
  end
end
