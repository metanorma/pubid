module Pubid::Plateau
  module Identifier
    class Handbook < Base
      def_delegators 'Pubid::Plateau::Identifier::Handbook', :type

      def self.get_renderer_class
        Renderer::Handbook
      end

      def self.type
        { key: :handbook, title: "Handbook" }
      end
    end
  end
end
