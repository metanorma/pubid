module Pubid::Bsi
  module Identifier
    class Corrigendum < Base
      def_delegators 'Pubid::Bsi::Identifier::Corrigendum', :type

      def self.type
        { key: :cor, title: "corrigendum" }
      end

      def self.get_renderer_class
        Renderer::Corrigendum
      end
    end
  end
end
