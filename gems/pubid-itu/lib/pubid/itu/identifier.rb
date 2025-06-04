module Pubid::Itu
  module Identifier
    class << self
      include Pubid::Core::Identifier

      # @see Pubid::Identifier::Base.parse
      def parse(*args)
        Base.parse(*args)
      end

      def resolve_identifier(parameters = {})
        return Question.new(**parameters) if parameters[:series].to_s.match?(/^SG/) && !parameters[:type]

        return Resolution.new(**parameters) if parameters[:series].to_s == "R"

        return SpecialPublication.new(**parameters) if parameters[:series].to_s == "OB"

        if parameters[:regulatory_publication]
          return RegulatoryPublication.new(
            **parameters.reject { |k, _| k == :regulatory_publication }.merge(
              { series: parameters[:regulatory_publication] },
            ),
          )
        end

        return Recommendation.new(**parameters) if parameters[:series] && !parameters[:type]

        super
      end
    end
  end
end
