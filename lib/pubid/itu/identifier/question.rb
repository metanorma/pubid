module Pubid::Itu
  module Identifier
    class Question < Base
      def_delegators 'Pubid::Itu::Identifier::Question', :type

      def self.type
        { key: :question, title: "Question" }
      end
    end
  end
end
