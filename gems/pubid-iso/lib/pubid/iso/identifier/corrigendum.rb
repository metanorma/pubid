require_relative "../renderer/corrigendum"
require_relative "../renderer/urn-corrigendum"

module Pubid::Iso
  module Identifier
    class Corrigendum < Supplement
      def_delegators 'Pubid::Iso::Identifier::Corrigendum', :type

      TYPED_STAGES = {
        dcor: {
          abbr: "DCOR",
          legacy_abbr: %w[DCor],
          name: "Draft Corrigendum",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 40.98 40.99],
        },
        fdcor: {
          abbr: "FDCOR",
          legacy_abbr: %w[FDCor FCOR],
          name: "Final Draft Corrigendum",
          harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
        },
      }.freeze

      def self.type
        { key: :cor, title: "Corrigendum", short: "COR" }
      end

      def self.get_renderer_class
        Renderer::Corrigendum
      end

      def urn
        raise Errors::NoEditionError, "Base document must have edition" unless base_has_edition?

        Renderer::UrnCorrigendum.new(to_h(deep: false)).render
      end
    end
  end
end
