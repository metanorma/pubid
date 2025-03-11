require_relative "../renderer/technical_specification"

module Pubid::Cen
  module Identifier
    class TechnicalSpecification < Base
      def_delegators 'Pubid::Cen::Identifier::TechnicalSpecification', :type

      def self.type
        { key: :ts, title: "Technical Specification", short: "TS" }
      end

      def self.get_renderer_class
        Renderer::TechnicalSpecification
      end
    end
  end
end
