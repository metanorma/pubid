# frozen_string_literal: true

module Pubid
  module Bipm
    module Identifiers
      # A Consultative-Committee guideline document (realization / calibration
      # guide). Printed from its short docnumber form, the relaton index key.
      #
      # Printed forms (all round-trip):
      #   "CCL-GD-MeP-1"    metre realization guide
      #   "CCEM-GD-RSI-1"   ampere realization guide
      #   "CCM-GD-RSI-2"    kilogram dissemination guide
      #
      # Shape: <committee>-GD-<kind>-<number>, where <kind> is "MeP" (mise en
      # pratique guide) or "RSI" (réalisation du SI guide). The committee reuses
      # the shared `group` attribute; the trailing sequence reuses `number`.
      class Guide < Identifier
        def self.type
          { key: :guide, web: :guide, title: "Guide", short: "guide" }
        end
      end
    end
  end
end
