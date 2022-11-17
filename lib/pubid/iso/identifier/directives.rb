module Pubid::Iso
  module Identifier
    class Directives < Base
      def_delegators 'Pubid::Iso::Identifier::Directives', :type

      TYPED_STAGES = {}.freeze

      def self.type
        :dir
      end

      def self.get_renderer_class
        Renderer::Dir
      end
    end
  end
end
