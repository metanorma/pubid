# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # SI Standard (Système International) identifier
      # IEEE/ASTM SI standards for metric system
      # Handles both:
      # - SI: Published standards (IEEE/ASTM SI 10-1997)
      # - PSI: Proposed SI (drafts: IEEE/ASTM PSI 10/D2, October 2015)
      class SiStandard < Identifier
        # Reliable string `number` for relaton's index key (see CodeNumber).
        include CodeNumber

        # TYPED_STAGES for SI standards
        TYPED_STAGES = [
          Components::TypedStage.new(
            abbr: ["SI"],
            type_code: "SI",
            stage_code: "published",
          ),
          Components::TypedStage.new(
            abbr: ["PSI"],
            type_code: "SI",
            stage_code: "draft",
          ),
        ].freeze

        # SI standards always have IEEE/ASTM publisher
        # Format: "IEEE/ASTM SI 10-1997" (published)
        #     or: "IEEE/ASTM PSI 10/D2, October 2015" (draft)

        # Use proper Draft component (Lutaml::Model object)
        attr_accessor :draft_obj
      end
    end
  end
end
