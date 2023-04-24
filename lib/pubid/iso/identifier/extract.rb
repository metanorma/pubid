require_relative "../renderer/extract"

module Pubid::Iso
  module Identifier
    class Extract < Base
      def_delegators 'Pubid::Iso::Identifier::Extract', :type

      TYPED_STAGES = {}.freeze

      def self.type
        { key: :ext, title: "Extract" }
      end

      def self.get_renderer_class
        Renderer::Extract
      end
    end
  end
end
