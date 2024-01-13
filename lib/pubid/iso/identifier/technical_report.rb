require_relative "../renderer/technical_report"

module Pubid::Iso
  module Identifier
    class TechnicalReport < Base
      def_delegators 'Pubid::Iso::Identifier::TechnicalReport', :type

      TYPED_STAGES = {
        dtr: {
          abbr: "DTR",
          name: "Draft Technical Report",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 40.98 40.99],
        },
        fdtr: {
          abbr: "FDTR",
          name: "Final Draft Technical Report",
          harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
        },
      }.freeze

      def self.type
        { key: :tr, title: "Technical Report", short: "TR" }
      end

      def self.get_renderer_class
        Renderer::TechnicalReport
      end
    end
  end
end
