module Pubid::Iso
  module Identifier
    class InternationalStandard < Base
      def_delegators 'Pubid::Iso::Identifier::InternationalStandard', :type

      TYPED_STAGES = {
        dp: {
          abbr: "DP",
          name: "Draft Proposal",
          harmonized_stages: %w[],
        },
        dis: {
          abbr: "DIS",
          name: "Draft International Standard",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 40.98 40.99],
        },
        fdis: {
          abbr: "FDIS",
          name: "Final Draft International Standard",
          harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
        },
        wdr: {
          abbr: "WDR",
          name: "Proposed for Withdrawal",
          harmonized_stages: %w[90.92],
        },
        wda: {
          abbr: "WDA",
          name: "Withdrawal Approved",
          harmonized_stages: %w[90.93],
        },
        wdar: {
          abbr: "WDAR",
          name: "Withdrawal Archived",
          harmonized_stages: %w[95.99],
        },
        is: {
          abbr: "IS",
          name: "International Standard",
          harmonized_stages: %w[60.00 60.60],
        },
      }.freeze

      def initialize(stage: nil, iteration: nil, **opts)
        if iteration && stage.nil?
          raise Errors::IsStageIterationError, "IS stage document cannot have iteration"
        end

        super
      end

      def typed_stage_abbrev
        if self.class::TYPED_STAGES.key?(stage)
          super
        else
          stage&.abbr
        end
      end

      def self.type
        { key: :is, title: "International Standard", short: nil }
      end
    end
  end
end
