module Pubid::Bsi
  module Identifier
    class PubliclyAvailableSpecification < Base
      def_delegators 'Pubid::Bsi::Identifier::PubliclyAvailableSpecification', :type

      def self.type
        { key: :pas, title: "Publicly Available Specification", short: "PAS" }
      end

      def self.get_renderer_class
        Renderer::PubliclyAvailableSpecification
      end
    end
  end
end
