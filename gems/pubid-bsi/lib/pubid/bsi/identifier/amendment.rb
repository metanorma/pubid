module Pubid::Bsi
  module Identifier
    class Amendment < Base
      def_delegators 'Pubid::Bsi::Identifier::Amendment', :type

      def self.type
        { key: :amd, title: "Amendment" }
      end

      def self.get_renderer_class
        Renderer::Amendment
      end
    end
  end
end
