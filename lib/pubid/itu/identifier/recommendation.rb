# require_relative "../renderer/recommendation"

module Pubid::Itu
  module Identifier
    class Recommendation < Base
      def_delegators 'Pubid::Itu::Identifier::Recommendation', :type

      def self.type
        { key: :r, title: "Recommendation", short: "REC" }
      end
    end
  end
end
