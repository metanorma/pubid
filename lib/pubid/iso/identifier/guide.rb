module Pubid::Iso
  module Identifier
    class Guide < Base
      def_delegators 'Pubid::Iso::Identifier::Guide', :type

      TYPED_STAGES = {}.freeze

      def self.get_renderer_class
        Renderer::Guide
      end

      def self.type
        :guide
      end
    end
  end
end
