module Pubid::Itu
  module Identifier
    class Contribution < Base
      def_delegators 'Pubid::Itu::Identifier::Contribution', :type

      def self.type
        { key: :contribution, title: "Contribution" }
      end

      def self.get_renderer_class
        Renderer::Contribution
      end
    end
  end
end
