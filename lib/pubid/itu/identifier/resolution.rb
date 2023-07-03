module Pubid::Itu
  module Identifier
    class Resolution < Base
      def_delegators 'Pubid::Itu::Identifier::Resolution', :type

      def self.type
        { key: :resolution, title: "Resolition" }
      end
    end
  end
end
