module Pubid::Itu
  module Identifier
    class Corrigendum < Supplement
      def_delegators 'Pubid::Itu::Identifier::Corrigendum', :type

      def self.type
        { key: :corrigendum, title: "Corrigendum" }
      end
    end
  end
end
