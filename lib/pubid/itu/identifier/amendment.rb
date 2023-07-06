module Pubid::Itu
  module Identifier
    class Amendment < Base
      def_delegators 'Pubid::Itu::Identifier::Amendment', :type

      def self.type
        { key: :amd, title: "Amendment" }
      end

      def self.get_renderer_class
        Renderer::Amendment
      end
    end
  end
end
