# frozen_string_literal: true

module Pubid
  module Nist
    module Identifiers
      # NIST Special Publication (SP)
      # Examples:
      # - "NIST SP 800-53" = Special Publication 800-53
      # - "NIST SP 800-53r5" = Special Publication 800-53 revision 5
      # - "NIST SP 800-57pt1r4" = Special Publication 800-57 part 1 revision 4
      class SpecialPublication < Identifier
        # Per Appendix A.2 of the NIST PubID Syntax (April 2022), the SP series
        # is subdivided into named subseries. The subseries number is the
        # leading token of a report-num like "800-53" or "1190GB-12". The
        # Builder exposes this as `identifier.subseries` so callers can query
        # which subseries a document belongs to.
        SP_SUBSERIES = %w[
          250 260 300 400 480 500 700 800 823 960 1190GB 1200 1500 1800 1900 2000 2100
        ].freeze

        TYPED_STAGES = [
          Pubid::Components::TypedStage.new(
            abbr: ["SP", "NIST SP", "NBS SP"], # Compound series
            stage_code: "published",
            type_code: "sp",
          ),
        ].freeze

        class << self
          def typed_stages
            TYPED_STAGES
          end

          def type
            { key: :sp,
            web: :special_publication, title: "NIST Special Publication", short: "SP" }
          end
        end

        def series_code
          "SP"
        end
      end
    end
  end
end
