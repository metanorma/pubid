# frozen_string_literal: true

module Pubid
  module Iec
    module Identifiers
      # Corrigendum Identifier
      class Corrigendum < SupplementIdentifier
        # `type` is NOT redeclared here — see the note on Amendment. The
        # redeclaration assigned the Symbol `:cor` on the from_hash path.
        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :pwi_cor,
            stage_code: :pwi,
            type_code: :cor,
            abbr: ["PWI Cor"],
            name: "Preliminary Work Item Corrigendum",
            harmonized_stages: %w[00.00 00.20 00.60 00.98 00.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :np_cor,
            stage_code: :np,
            type_code: :cor,
            abbr: ["NP Cor"],
            name: "New Proposal Corrigendum",
            harmonized_stages: %w[10.00 10.20 10.60 10.92 10.98],
          ),
          Pubid::Components::TypedStage.new(
            code: :anw_cor,
            stage_code: :anw,
            type_code: :cor,
            abbr: ["ANW Cor"],
            name: "Approved New Work Item Corrigendum",
            harmonized_stages: %w[10.99 20.00],
          ),
          Pubid::Components::TypedStage.new(
            code: :wdcor,
            stage_code: :wd,
            type_code: :cor,
            abbr: ["WDCor"],
            name: "Working Draft Corrigendum",
            harmonized_stages: %w[20.20 20.60 20.98 20.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :cdcor,
            stage_code: :cd,
            type_code: :cor,
            abbr: ["CDCor"],
            short_abbr: "CDCor",
            long_abbr: "CD Cor",
            name: "Committee Draft Corrigendum",
            harmonized_stages: %w[30.00 30.20 30.60 30.92 30.98 30.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :dcor,
            stage_code: :dcor,
            type_code: :cor,
            abbr: ["DCOR"],
            short_abbr: "DCOR",
            long_abbr: "DCor",
            name: "Draft Corrigendum",
            harmonized_stages: %w[40.00 40.20 40.60 40.92 40.98 40.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :fdcor,
            stage_code: :fdcor,
            type_code: :cor,
            abbr: ["FDCOR", "PRF Cor"],
            short_abbr: "FDCOR",
            long_abbr: "FDCor",
            name: "Final Draft Corrigendum",
            harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :pubcor,
            stage_code: :published,
            type_code: :cor,
            abbr: ["Cor", "COR"],
            short_abbr: "COR",
            long_abbr: "Cor",
            name: "Corrigendum",
            harmonized_stages: %w[60.00 60.60 90.20 90.60 90.92 90.93 90.99
                                  95.20 95.60 95.92 95.99],
          ),
        ].freeze

        def self.type
          { key: :cor,
            web: :corrigendum, title: "Corrigendum", short: "COR" }
        end
      end
    end
  end
end
