require_relative "../renderer/guide"

module Pubid::Cen
  module Identifier
    class Guide < Base
      def_delegators 'Pubid::Cen::Identifier::Guide', :type

      def self.get_renderer_class
        Renderer::Guide
      end

      def self.type
        { key: :guide, title: "Guide", short: "Guide" }
      end
    end
  end
end
