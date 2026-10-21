# frozen_string_literal: true

module Pubid
  module Iec
    module Identifiers
      # Publicly Available Specification identifier class
      # Single Responsibility: Represents IEC PAS documents
      class PubliclyAvailableSpecification < Base
        # Convert v1 hash-based TYPED_STAGES to v2 object-based
        # From gems/pubid-iec/lib/pubid/iec/identifier/publicly_available_specification.rb
        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :pwi_pas,
            stage_code: :pwi,
            type_code: :pas,
            abbr: ["PWI PAS"],
            name: "Preliminary Work Item Publicly Available Specification",
            harmonized_stages: %w[00.00 00.20 00.60 00.98 00.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :np_pas,
            stage_code: :np,
            type_code: :pas,
            abbr: ["NP PAS"],
            name: "New Proposal Publicly Available Specification",
            harmonized_stages: %w[10.00 10.20 10.60 10.92 10.98],
          ),
          Pubid::Components::TypedStage.new(
            code: :anw_pas,
            stage_code: :anw,
            type_code: :pas,
            abbr: ["ANW PAS"],
            name: "Approved New Work Item Publicly Available Specification",
            harmonized_stages: %w[10.99 20.00],
          ),
          Pubid::Components::TypedStage.new(
            code: :wd_pas,
            stage_code: :wd,
            type_code: :pas,
            abbr: ["WD PAS"],
            name: "Working Draft Publicly Available Specification",
            harmonized_stages: %w[20.20 20.60 20.98 20.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :cdpas,
            stage_code: :cd,
            type_code: :pas,
            abbr: ["CDPAS"],
            name: "Committee Draft Publicly Available Specification",
            harmonized_stages: %w[30.00 30.20 30.60 30.92 30.98 30.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :dpas,
            stage_code: :draft,
            type_code: :pas,
            # CDPAS is the 50.20 row of IEC's stage-code table
            # ("Draft circulated as DPAS") — see data/iec/stage-codes.md
            abbr: ["DPAS", "CDPAS"],
            name: "Draft Publicly Available Specification",
            harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :pas,
            stage_code: :published,
            type_code: :pas,
            abbr: ["PAS"],
            name: "Publicly Available Specification",
            harmonized_stages: %w[60.00 60.60 90.20 90.60 90.92 90.93 90.99
                                  95.20 95.60 95.92 95.99],
          ),
        ].freeze

        # Project stages specific to PAS
        PROJECT_STAGES = {
          PRVDPAS: {
            abbr: "PRVDPAS",
            name: "Preparation of RVDPAS",
            harmonized_stages: %w[50.60],
          },
        }.freeze

        def self.type
          { key: :pas,
            web: :publicly_available_specification, title: "Publicly Available Specification", short: "PAS" }
        end

      end
    end
  end
end
