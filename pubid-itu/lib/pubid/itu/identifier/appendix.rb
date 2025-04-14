module Pubid::Itu
  module Identifier
    class Appendix < Supplement
      def_delegators 'Pubid::Itu::Identifier::Appendix', :type

      def self.type
        { key: :appendix, title: "Appendix" }
      end
    end
  end
end
