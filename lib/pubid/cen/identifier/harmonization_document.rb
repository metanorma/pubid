require_relative "../renderer/guide"

module Pubid::Cen
  module Identifier
    class HarmonizationDocument < Base
      def_delegators 'Pubid::Cen::Identifier::HarmonizationDocument', :type

      def self.get_renderer_class
        Renderer::HarmonizationDocument
      end

      def self.type
        { key: :hd, title: "Harmonization Document", short: "HD" }
      end
    end
  end
end
