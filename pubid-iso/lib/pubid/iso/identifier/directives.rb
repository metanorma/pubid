require_relative "../renderer/dir"
require_relative "../renderer/urn-dir"

module Pubid::Iso
  module Identifier
    class Directives < Base
      def_delegators 'Pubid::Iso::Identifier::Directives', :type

      TYPED_STAGES = {}.freeze

      attr_accessor :edition_publisher

      def initialize(edition_publisher: nil, **opts)
        super(**opts)
        @edition_publisher = edition_publisher
      end

      def self.type
        { key: :dir, title: "Directives", short: "DIR" }
      end

      def self.get_renderer_class
        Renderer::Dir
      end

      def urn
        Renderer::UrnDir.new(to_h(deep: false)).render
      end

      def render_joint_document(joint_document)
        # remove "DIR" for short joint document format
        "#{@joint_document}".sub(" DIR", "")
      end
    end
  end
end
