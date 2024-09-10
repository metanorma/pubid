module Pubid::Itu
  module Identifier
    class SpecialPublication < Base
      def_delegators 'Pubid::Itu::Identifier::SpecialPublication', :type

      def self.type
        { key: :sp, title: "Special Publication", short: "SP" }
      end

      def self.get_renderer_class
        Renderer::SpecialPublication
      end
    end
  end
end
