module Pubid::Ccsds
  module Identifier
    class Corrigendum < Base
      def_delegators 'Pubid::Ccsds::Identifier::Corrigendum', :type

      attr_accessor :base

      def initialize(base: nil, **opts)
        super(**opts)
        if base.is_a?(Hash)
          @base = Identifier.create(**base)
        else
          @base = base
        end
      end

      def self.type
        { key: :corrigendum, title: "Corrigendum", short: "corrigendum" }
      end

      def self.get_renderer_class
        Renderer::Corrigendum
      end
    end
  end
end
