# frozen_string_literal: true

module Pubid
  module Iec
    module Identifiers
      # Interpretation Sheet identifier class
      # Single Responsibility: Represents IEC ISH documents
      # Dual role: Can be primary document or supplement
      class InterpretationSheet < SupplementIdentifier
        # Convert v1 hash-based TYPED_STAGES to v2 object-based
        # From gems/pubid-iec/lib/pubid/iec/identifier/interpretation_sheet.rb
        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :pwi_ish,
            stage_code: :pwi,
            type_code: :ish,
            abbr: ["PWI ISH"],
            name: "Preliminary Work Item Interpretation Sheet",
            harmonized_stages: %w[00.00 00.20 00.60 00.98 00.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :np_ish,
            stage_code: :np,
            type_code: :ish,
            abbr: ["NP ISH"],
            name: "New Proposal Interpretation Sheet",
            harmonized_stages: %w[10.00 10.20 10.60 10.92 10.98],
          ),
          Pubid::Components::TypedStage.new(
            code: :anw_ish,
            stage_code: :anw,
            type_code: :ish,
            abbr: ["ANW ISH"],
            name: "Approved New Work Item Interpretation Sheet",
            harmonized_stages: %w[10.99 20.00],
          ),
          Pubid::Components::TypedStage.new(
            code: :wd_ish,
            stage_code: :wd,
            type_code: :ish,
            abbr: ["WD ISH"],
            name: "Working Draft Interpretation Sheet",
            harmonized_stages: %w[20.20 20.60 20.98 20.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :cdish,
            stage_code: :cd,
            type_code: :ish,
            abbr: ["CDISH"],
            name: "Committee Draft Interpretation Sheet",
            harmonized_stages: %w[30.00 30.20 30.60 30.92 30.98 30.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :dish,
            stage_code: :draft,
            type_code: :ish,
            # CDISH is the 50.20 row of IEC's stage-code table
            # ("Draft circulated as DISH") — see data/iec/stage-codes.md
            abbr: ["DISH", "CDISH"],
            name: "Draft Interpretation Sheet",
            harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :ish,
            stage_code: :published,
            type_code: :ish,
            abbr: ["ISH"],
            name: "Interpretation Sheet",
            harmonized_stages: %w[60.00 60.60 90.20 90.60 90.92 90.93 90.99
                                  95.20 95.60 95.92 95.99],
          ),
        ].freeze

        # Project stages specific to Interpretation Sheets
        PROJECT_STAGES = {
          decdish: {
            abbr: "DECDISH",
            name: "DISH at editing check",
            harmonized_stages: %w[50.00],
          },
          prvdish: {
            abbr: "PRVDISH",
            name: "Preparation of RVDISH",
            harmonized_stages: %w[50.60],
          },
          rdish: {
            abbr: "RDISH",
            name: "DISH received and registered",
            harmonized_stages: %w[50.00],
          },
          tdish: {
            abbr: "TDISH",
            name: "Translation of DISH",
            harmonized_stages: %w[50.00],
          },
        }.freeze

        def self.type
          { key: :ish,
            web: :interpretation_sheet, title: "Interpretation Sheet", short: "ISH" }
        end
      end
    end
  end
end
