module Pubid::Itu
  module Identifier
    class << self
      include Pubid::Core::Identifier

      # @see Pubid::Identifier::Base.parse
      def parse(*args)
        Base.parse(*args)
      end

      def resolve_identifier(parameters = {})
        return Question.new(**parameters) if parameters[:series].to_s.match?(/^SG/)

        return Resolution.new(**parameters) if parameters[:series].to_s == "R"

        return SpecialPublication.new(**parameters) if parameters[:series].to_s == "OB"

        return Recommendation.new(**parameters) if parameters[:series]

        super
      end
    end
  end
end
