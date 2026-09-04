# frozen_string_literal: true

module Pubid
  module Iec
    module Identifiers
      # Amendment Identifier
      class Amendment < SupplementIdentifier
        # `type` is NOT redeclared here. It is derived from `typed_stage` by
        # Pubid::Iec::Identifier#type, like every other IEC type. A redeclared
        # attribute shadowed that reader and, because `type` is not serialized,
        # its class-level default assigned the Symbol `:amd` on the from_hash
        # path where the parse path assigns a Components::Type — so
        # `from_hash(to_hash) != parse` for every amendment.
        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :pwi_amd,
            stage_code: :pwi,
            type_code: :amd,
            abbr: ["PWI Amd"],
            name: "Preliminary Work Item Amendment",
            harmonized_stages: %w[00.00 00.20 00.60 00.98 00.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :np_amd,
            stage_code: :np,
            type_code: :amd,
            abbr: ["NP Amd"],
            name: "New Proposal Amendment",
            harmonized_stages: %w[10.00 10.20 10.60 10.92 10.98],
          ),
          Pubid::Components::TypedStage.new(
            code: :anw_amd,
            stage_code: :anw,
            type_code: :amd,
            abbr: ["ANW Amd"],
            name: "Approved New Work Item Amendment",
            harmonized_stages: %w[10.99 20.00],
          ),
          Pubid::Components::TypedStage.new(
            code: :wd_amd,
            stage_code: :wd,
            type_code: :amd,
            abbr: ["WD Amd"],
            name: "Working Draft Amendment",
            harmonized_stages: %w[20.20 20.60 20.98 20.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :cdamd,
            stage_code: :cd,
            type_code: :amd,
            abbr: ["CDAM"],
            short_abbr: "CDV",
            long_abbr: "CD",
            name: "Committee Draft Amendment",
            harmonized_stages: %w[30.00 30.20 30.60 30.92 30.98 30.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :damd,
            stage_code: :damd,
            type_code: :amd,
            abbr: ["DAM"],
            short_abbr: "DAM",
            long_abbr: "DAm",
            name: "Draft Amendment",
            harmonized_stages: %w[40.00 40.20 40.60 40.92 40.98 40.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :fdamd,
            stage_code: :fdamd,
            type_code: :amd,
            abbr: ["FDAM", "PRF Amd"],
            short_abbr: "FDIS",
            long_abbr: "FDIS",
            name: "Final Draft Amendment",
            harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :pubamd,
            stage_code: :published,
            type_code: :amd,
            abbr: ["Amd", "AMD"],
            short_abbr: "AMD",
            long_abbr: "Amd",
            name: "Amendment",
            harmonized_stages: %w[60.00 60.60 90.20 90.60 90.92 90.93 90.99
                                  95.20 95.60 95.92 95.99],
          ),
        ].freeze

        def self.type
          { key: :amd,
            web: :amendment, title: "Amendment", short: "AMD" }
        end
      end
    end
  end
end
