require_relative "../renderer/technical_specification"

module Pubid::Iso
  module Identifier
    class TechnicalSpecification < Base
      def_delegators 'Pubid::Iso::Identifier::TechnicalSpecification', :type

      TYPED_STAGES = {
        dts: {
          abbr: "DTS",
          name: "Draft Technical Specification",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 40.98 40.99],
        },
        fdts: {
          abbr: "FDTS",
          name: "Final Draft Technical Specification",
          harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
        },
      }.freeze

      def self.type
        { key: :ts, title: "Technical Specification", short: "TS" }
      end

      def self.get_renderer_class
        Renderer::TechnicalSpecification
      end
    end
  end
end
