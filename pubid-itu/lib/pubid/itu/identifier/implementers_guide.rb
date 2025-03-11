module Pubid::Itu
  module Identifier
    class ImplementersGuide < Base
      def_delegators 'Pubid::Itu::Identifier::ImplementersGuide', :type

      def self.type
        { key: :imp, title: "Implementer's Guide" }
      end

      def self.get_renderer_class
        Renderer::ImplementersGuide
      end
    end
  end
end
