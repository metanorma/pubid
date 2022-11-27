module Pubid::Iso
  module Identifier
    class Corrigendum < Supplement
      def_delegators 'Pubid::Iso::Identifier::Corrigendum', :type

      TYPED_STAGES = {
        dcor: {
          abbr: "DCOR",
          name: "Draft Corrigendum",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 50.00 50.20 50.60 50.92],
        },
        fdcor: {
          abbr: "FDCOR",
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

      def urn
        raise Errors::NoEditionError, "Base document must have edition" unless base_has_edition?

        Renderer::UrnCorrigendum.new(get_params).render
      end
    end
  end
end
