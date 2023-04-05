module Pubid::Bsi
  class Parser < Pubid::Core::Parser
    rule(:year) do
      match('\d').repeat(2, 4).as(:year)
    end

    rule(:type) do
      array_to_str(Identifier.config.types.map { |type| type.type[:short] }.compact).as(:type)
    end

    rule(:part) do
      str("-") >> digits.as(:part)
    end

    rule(:edition) do
      str("v") >> (digits >> dot >> digits).as(:edition)
    end

    rule(:supplement) do
      (str("+") >> match("[AC]").as(:type) >> digits.as(:number) >> str(":") >> year).as(:supplement)
    end

    rule(:expert_commentary) do
      space >> str("ExComm").as(:expert_commentary)
    end

    rule(:tracked_changes) do
      str(" - TC").as(:tracked_changes)
    end

    rule(:national_annexes) do
      (str("NA") >> supplement.maybe >> str(" to ").ignore).as(:national_annexes)
    end

    rule(:identifier) do
      national_annexes.maybe >> str("BSI ").maybe >> type >> space >>
        (
          (digits.as(:number) >> part.maybe >> (space >> edition).maybe >>
            (space? >> str(":") >> year >> (dash >> month_digits.as(:month)).maybe).maybe) |
            (expert_commentary.absent? >> space? >> match("[^+ ]").repeat(1)).repeat.as(:adopted)
        ) >> supplement.maybe >> expert_commentary.maybe >> tracked_changes.maybe
    end

    rule(:root) { identifier }
  end
end
