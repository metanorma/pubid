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
      (str("/") | space).maybe >>
        array_to_str(
          Identifier.config.types.map { |type| [type.type[:short], type.type[:short]&.upcase] }
                    .flatten.compact).as(:type)
    end

    rule(:stage) do
      (str("pr") | str("Fpr")).as(:stage)
    end

    rule(:supplement_matcher) do
      ((str("AC").as(:type) >> digits.as(:number).maybe) |
        (str("A").as(:type) >> digits.as(:number))) >> str(":") >> year
    end

    rule(:incorporated_supplement) do
      str("+") >> supplement_matcher.as(:incorporated_supplements)
    end

    rule(:supplement) do
      str("/") >> supplement_matcher.as(:supplement)
    end

    rule(:identifier) do
      stage.maybe >> originator.maybe >> ((type.maybe >> space >> digits.as(:number) >> part >>
        (str(":") >> year).maybe) | (space >> (match("[^+/]").repeat(1) >>
        # XXX: hack to match part after "/" for identifiers like
        # EN ISO/IEC 80079-34:2020 ED2
        # but march only part before "/" for identifiers like
        # EN ISO 13485:2016/AC:2016
        (supplement.absent? >> match("[^+]").repeat(1)).maybe).as(:adopted))) >>
        supplement.maybe >> incorporated_supplement.repeat
    end

    rule(:root) { identifier }
  end
end
