module Pubid::Cen
  class Parser < Pubid::Core::Parser
    rule(:part) do
      (str("-") >> digits.as(:part)).repeat
    end

    rule(:organization) do
      str("EN") | str("CEN") | str("CLC")
    end

    rule(:originator) do
      organization.as(:publisher) >>
        (space? >> (str("/") | str("-")) >> organization.as(:copublisher)).repeat
    end

    rule(:type) do
      (str("/") | space) >>
        array_to_str(
          Identifier.config.types.map { |type| [type.type[:short], type.type[:short].upcase] }
                    .flatten.compact).as(:type)
    end

    rule(:stage) do
      (str("pr") | str("Fpr")).as(:stage)
    end

    rule(:identifier) do
      stage.maybe >> originator >> type.maybe >> space >> digits.as(:number) >> part >>
        (str(":") >> year).maybe
    end

    rule(:root) { identifier }
  end
end
