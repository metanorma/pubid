require_relative "../renderer/extract"
require_relative "../renderer/urn-extract"

module Pubid::Iso
  module Identifier
    class Extract < Base
      def_delegators 'Pubid::Iso::Identifier::Extract', :type

      TYPED_STAGES = {}.freeze

      def self.type
        { key: :ext, title: "Extract", short: "EXT" }
      end

      def self.get_renderer_class
        Renderer::Extract
      end

      def urn
        Renderer::UrnExtract.new(to_h(deep: false)).render
      end
    end
  end
end
