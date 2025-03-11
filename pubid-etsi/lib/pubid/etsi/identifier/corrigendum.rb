module Pubid::Etsi
  module Identifier
    class Corrigendum < Supplement
      def_delegators 'Pubid::Etsi::Identifier::Corrigendum', :type

      def self.type
        { key: :corrigendum, title: "Corrigendum" }
      end
    end
  end
end
