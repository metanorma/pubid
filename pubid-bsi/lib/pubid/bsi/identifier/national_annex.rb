module Pubid::Bsi
  module Identifier
    class NationalAnnex < Base
      attr_accessor :base

      def_delegators 'Pubid::Bsi::Identifier::NationalAnnex', :type

      def initialize(base: nil, **opts)

        super(**opts)
        @base = base
      end

      def self.type
        { key: :na, title: "National Annex", short: "NA" }
      end

      def self.get_renderer_class
        Renderer::NationalAnnex
      end
    end
  end
end
