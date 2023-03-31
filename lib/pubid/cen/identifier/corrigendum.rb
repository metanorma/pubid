module Pubid::Cen
  module Identifier
    class Corrigendum < Base
      def_delegators 'Pubid::Cen::Identifier::Corrigendum', :type
      attr_accessor :base

      def initialize(number: nil, base: nil, **opts)
        super(**opts.merge(number: number))
        @base = base
      end

      def self.type
        { key: :cor, title: "corrigendum" }
      end

      def self.get_renderer_class
        Renderer::Corrigendum
      end
    end
  end
end
