module Pubid::Iso
  module Identifier
    class Guide < Base
      def_delegators 'Pubid::Iso::Identifier::Guide', :type

      TYPED_STAGES = {
        dguide: {
          abbr: "DGuide",
          name: "Draft Guide",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 50.00 50.20 50.60 50.92],
        },
        fdguide: {
          abbr: "FDGuide",
          name: "Final Draft Guide",
          harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
        },
      }.freeze

      def self.get_renderer_class
        Renderer::Guide
      end

      def self.type
        :guide
      end
    end
  end
end
