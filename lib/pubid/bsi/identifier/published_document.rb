module Pubid::Bsi
  module Identifier
    class PublishedDocument < Base
      def_delegators 'Pubid::Bsi::Identifier::PublishedDocument', :type

      def self.type
        { key: :pd, title: "Published Document" }
      end

      def self.get_renderer_class
        Renderer::PublishedDocument
      end
    end
  end
end
