module Pubid::Cen
  module Identifier
    class Amendment < Base
      def_delegators 'Pubid::Cen::Identifier::Amendment', :type
      attr_accessor :base

      def initialize(base: nil, **opts)
        super(**opts)
        @base = base
      end

      def self.type
        { key: :amd, title: "Amendment" }
      end

      def self.get_renderer_class
        Renderer::Amendment
      end
    end
  end
end
