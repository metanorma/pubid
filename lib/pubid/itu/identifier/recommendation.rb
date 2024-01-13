module Pubid::Itu
  module Identifier
    class Recommendation < Base
      def_delegators 'Pubid::Itu::Identifier::Recommendation', :type

      def self.type
        { key: :recommendation, title: "Recommendation", short: "REC" }
      end
    end
  end
end
