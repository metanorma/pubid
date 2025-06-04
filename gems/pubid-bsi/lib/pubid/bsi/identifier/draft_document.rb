module Pubid::Bsi
  module Identifier
    class DraftDocument < Base
      def_delegators 'Pubid::Bsi::Identifier::DraftDocument', :type

      def self.type
        { key: :dd, title: "Draft Document", short: "DD" }
      end

      def self.get_renderer_class
        Renderer::DraftDocument
      end
    end
  end
end
