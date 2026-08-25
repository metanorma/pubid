# frozen_string_literal: true

module Pubid
  module Bipm
    module Identifiers
      # The SI Brochure — a single bespoke record. The English form drops the
      # "sur le SI" phrase the French form carries.
      #
      # Printed forms (both round-trip):
      #   "BIPM SI Brochure 9e v3.01 (2019/2024, E)"
      #   "BIPM SI Brochure sur le SI 9e v3.01 (2019/2024, F)"
      class SiBrochure < Identifier
        def self.type
          { key: :si_brochure, web: :si_brochure,
            title: "SI Brochure", short: "si-brochure" }
        end

        # MR: `bipm.si-brochure.<edition>-<version>[.<lang>]` for the brochure
        # itself, `bipm.si-brochure.<variant>` for a derived product. Exactly
        # one of `variant` / `edition` is set (the grammar guarantees it).
        def mr_type
          "si-brochure"
        end

        # The edition is folded in here rather than emitted through
        # `mr_edition`, whose base implementation expects a Components::Edition.
        def mr_number_with_part
          variant ? mr_slug(variant) : mr_slug(edition, version)
        end
      end
    end
  end
end
