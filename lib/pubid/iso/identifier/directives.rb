module Pubid::Iso
  module Identifier
    class Directives < Base
      def_delegators 'Pubid::Iso::Identifier::Directives', :type

      TYPED_STAGES = {}.freeze

      def self.type
        { key: :dir, title: "Directives" }
      end

      def self.get_renderer_class
        Renderer::Dir
      end

      def urn
        Renderer::UrnDir.new(get_params).render
      end

      def render_joint_document(joint_document)
        # remove "DIR" for short joint document format
        "#{@joint_document}".sub(" DIR", "")
      end
    end
  end
end
