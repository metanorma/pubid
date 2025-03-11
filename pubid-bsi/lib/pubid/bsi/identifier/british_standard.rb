module Pubid::Bsi
  module Identifier
    class BritishStandard < Base
      def_delegators 'Pubid::Bsi::Identifier::BritishStandard', :type

      def self.type
        { key: :bs, title: "British Standard", short: "BS" }
      end
    end
  end
end
