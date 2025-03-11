module Pubid::Itu
  module Identifier
    class RegulatoryPublication < Base
      def_delegators 'Pubid::Itu::Identifier::RegulatoryPublication', :type

      def self.type
        { key: :reg, title: "Regulatory Publication", short: "REG" }
      end
    end
  end
end
