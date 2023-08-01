module Pubid::Itu
  module Identifier
    class Annex < Supplement
      def_delegators 'Pubid::Itu::Identifier::Annex', :type

      def self.type
        { key: :annex, title: "Annex" }
      end
    end
  end
end
