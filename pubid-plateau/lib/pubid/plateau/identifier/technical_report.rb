module Pubid::Plateau
  module Identifier
    class TechnicalReport < Base
      def_delegators 'Pubid::Plateau::Identifier::TechnicalReport', :type

      def self.get_renderer_class
        Renderer::TechnicalReport
      end

      def self.type
        { key: :tr, title: "Technical Report", values: ["Technical Report"] }
      end
    end
  end
end
