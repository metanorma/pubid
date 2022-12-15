module Pubid::Iso
  module Identifier
    class TechnicalCommittee < Base
      def_delegators 'Pubid::Iso::Identifier::TechnicalCommittee', :type

      TYPED_STAGES = {}.freeze

      def self.type
        { key: :tc, title: "Technical Committee" }
      end

      def self.get_renderer_class
        Renderer::TechnicalCommittee
      end
    end
  end
end
