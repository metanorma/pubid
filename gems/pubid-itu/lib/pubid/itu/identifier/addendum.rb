module Pubid::Itu
  module Identifier
    class Addendum < Supplement
      def_delegators 'Pubid::Itu::Identifier::Addendum', :type

      def self.type
        { key: :addendum, title: "Addendum" }
      end
    end
  end
end
