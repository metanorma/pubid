module Pubid::Iso
  module Identifier
    class Amendment < Supplement
      def_delegators 'Pubid::Iso::Identifier::Amendment', :type

      TYPED_STAGES = {
        damd: {
          abbr: "DAM",
          name: "Draft Amendment",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 50.00 50.20 50.60 50.92],
        },
        fdamd: {
          abbr: "FDAM",
          name: "Final Draft Amendment",
          harmonized_stages: %w[50.00 50.20 50.60 50.92],
        },
      }.freeze

      def self.type
        :amd
      end

      def self.get_renderer_class
        Renderer::Amendment
      end
    end
  end
end
