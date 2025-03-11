module Pubid::Itu
  module Identifier
    class Amendment < Supplement
      def_delegators 'Pubid::Itu::Identifier::Amendment', :type

      def self.type
        { key: :amendment, title: "Amendment" }
      end
    end
  end
end
