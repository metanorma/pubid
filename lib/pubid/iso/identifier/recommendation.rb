module Pubid::Iso
  module Identifier
    class Recommendation < Base
      def_delegators 'Pubid::Iso::Identifier::Recommendation', :type

      TYPED_STAGES = {}.freeze

      def self.type
        :r
      end

      def self.get_renderer_class
        Renderer::Recommendation
      end
    end
  end
end
