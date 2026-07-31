# frozen_string_literal: true

module Pubid
  module Jcgm
    module Identifiers
      # A JCGM corrigendum. Two surface forms are supported:
      #
      #   "JCGM 200:2008 Corrigendum"      — base guide + trailing " Corrigendum"
      #                                       word, no iteration number
      #   "JCGM 101:2008/Cor 1:2009"       — base guide + slash-separated
      #                                       numbered corrigendum with date
      #
      # The first form is the JCGM-native convention. The second mirrors the
      # ISO/IEC supplement syntax and is needed to round-trip identifiers like
      # "JCGM 101:2008/Cor 1:2009" (corrigendum to GUM Supplement 1).
      class Corrigendum < SupplementIdentifier
        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :pubcorr,
            stage_code: :published,
            type_code: :corrigendum,
            abbr: %w[Corrigendum Cor],
            name: "Corrigendum",
            harmonized_stages: %w[60.00 60.60],
          ),
        ].freeze

        def self.type
          { key: :corrigendum, title: "Corrigendum", short: "Corr" }
        end
      end
    end
  end
end
