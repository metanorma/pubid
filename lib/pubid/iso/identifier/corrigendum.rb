module Pubid::Iso
  module Identifier
    class Corrigendum < Supplement
      def_delegators 'Pubid::Iso::Identifier::Corrigendum', :type

      TYPED_STAGES = {
        dcor: {
          abbr: { short: "DCOR", long: "DCor" },
          name: "Draft Corrigendum",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 50.00 50.20 50.60 50.92],
        },
        fdcor: {
          abbr: { short: "FDCOR", long: "FDCor" },
          name: "Final Draft Corrigendum",
          harmonized_stages: %w[50.00 50.20 50.60 50.92],
        },
      }.freeze

      def self.type
        :cor
      end

      def self.get_renderer_class
        Renderer::Corrigendum
      end
    end
  end
end
