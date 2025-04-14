module Pubid::Bsi
  module Identifier
    class Flex < Base
      def_delegators 'Pubid::Bsi::Identifier::Flex', :type

      def self.type
        { key: :flex, title: "Flex", short: "Flex" }
      end

      def self.get_renderer_class
        Renderer::Flex
      end
    end
  end
end
