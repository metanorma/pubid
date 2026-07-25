# frozen_string_literal: true

module Pubid
  module Iec
    module Identifiers
      # International Standard identifier class
      # Single Responsibility: Represents IEC International Standard documents
      class InternationalStandard < Base
        # International Standards need a TypedStage with empty abbr for published standards
        # From gems/pubid-iec/lib/pubid/iec/identifier/international_standard.rb
        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            code: :pwi,
            stage_code: :pwi,
            type_code: :is,
            abbr: %w[PWI PNW NWIP BWG AWIN AMW],
            name: "Preliminary Work Item",
            harmonized_stages: %w[00.00 00.20 00.60 00.98 00.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :np,
            stage_code: :np,
            type_code: :is,
            abbr: ["NP"],
            name: "New Proposal",
            harmonized_stages: %w[10.00 10.20 10.60 10.92 10.98],
          ),
          Pubid::Components::TypedStage.new(
            code: :anw,
            stage_code: :anw,
            type_code: :is,
            abbr: ["ANW"],
            name: "Approved New Work Item",
            harmonized_stages: %w[10.99 20.00],
          ),
          Pubid::Components::TypedStage.new(
            code: :wd,
            stage_code: :wd,
            type_code: :is,
            abbr: ["WD"],
            name: "Working Draft",
            harmonized_stages: %w[20.20 20.60 20.98 20.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :cd,
            stage_code: :cd,
            type_code: :is,
            abbr: %w[CD 2CD 3CD 4CD 5CD 6CD 7CD 8CD 9CD
                     ACD A2CD A3CD A4CD A5CD A6CD A7CD A8CD A9CD
                     CDM],
            name: "Committee Draft",
            harmonized_stages: %w[30.00 30.20 30.60 30.92 30.98 30.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :cdv,
            stage_code: :cdv,
            type_code: :is,
            abbr: %w[CDV ACDV CCDV CDVM NCDV],
            name: "Committee Draft for Vote",
            harmonized_stages: %w[40.00 40.20 40.60 40.92 40.98 40.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :fdis,
            stage_code: :fdis,
            type_code: :is,
            abbr: %w[FDIS PRF NFDIS NADIS RDISH RFDIS CFDIS],
            name: "Final Draft International Standard",
            harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
          ),
          Pubid::Components::TypedStage.new(
            code: :is,
            stage_code: :published,
            type_code: :is,
            abbr: ["", "BPUB", "PPUB", "APUB", "WPUB", "DELPUB",
                   "RR", "CAN"],
            name: "International Standard",
            harmonized_stages: %w[60.00 60.60 90.20 90.60 90.92 90.93 90.99
                                  95.20 95.60 95.92 95.99],
          ),
        ].freeze

        # Project stages specific to International Standards
        # These are IEC-specific workflow stages
        PROJECT_STAGES = {
          afdis: {
            abbr: "AFDIS",
            name: "Approved for FDIS",
            harmonized_stages: %w[40.99],
          },
          ccdv: {
            abbr: "CCDV",
            name: "Draft circulated as CDV",
            harmonized_stages: %w[40.20],
          },
          cdvm: {
            abbr: "CDVM",
            name: "Rejected CDV to be discussed at a meeting",
            harmonized_stages: %w[40.91],
          },
          cfdis: {
            abbr: "CFDIS",
            name: "Draft circulated as FDIS",
            harmonized_stages: %w[50.20],
          },
          decfdis: {
            abbr: "DECFDIS",
            name: "FDIS at editing check",
            harmonized_stages: %w[50.00],
          },
          ncdv: {
            abbr: "NCDV",
            name: "CDV rejected",
            harmonized_stages: %w[40.91],
          },
          nfdis: {
            abbr: "NFDIS",
            name: "FDIS rejected",
            harmonized_stages: %w[50.92],
          },
          prvc: {
            abbr: "PRVC",
            name: "Preparation of RVC",
            harmonized_stages: %w[40.60],
          },
          prvd: {
            abbr: "PRVD",
            name: "Preparation of RVD",
            harmonized_stages: %w[50.60],
          },
          rfdis: {
            abbr: "RFDIS",
            name: "FDIS received and registered",
            harmonized_stages: %w[50.00],
          },
          tcdv: {
            abbr: "TCDV",
            name: "Translation of CDV",
            harmonized_stages: %w[40.00],
          },
        }.freeze

        def self.type
          { key: :is,
            web: :international_standard, title: "International Standard", short: nil }
        end
      end
    end
  end
end
