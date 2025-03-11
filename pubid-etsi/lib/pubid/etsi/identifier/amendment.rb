module Pubid::Etsi
  module Identifier
    class Amendment < Supplement
      def_delegators 'Pubid::Etsi::Identifier::Amendment', :type

      def self.type
        { key: :amendment, title: "Amendment" }
      end
    end
  end
end
