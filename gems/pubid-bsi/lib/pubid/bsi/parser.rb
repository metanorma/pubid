module Pubid::Bsi
  class Parser < Pubid::Core::Parser
    rule(:year) do
      match('\d').repeat(2, 4).as(:year)
    end

    rule(:type) do
      national_annex.maybe >> array_to_str(Identifier.config.types.map { |type| type.type[:short] }.compact).as(:type)
    end

    rule(:part) do
      str("-") >> digits.as(:part)
    end

    rule(:edition) do
      str("v") >> (digits >> dot >> digits).as(:edition)
    end

    rule(:supplement) do
      (str("+") >> match("[AC]").as(:type) >> digits.as(:number) >> (str(":") >> year).maybe).as(:supplement)
    end

    rule(:expert_commentary) do
      space >> str("ExComm").as(:expert_commentary)
    end

    rule(:tracked_changes) do
      str(" - TC").as(:tracked_changes)
    end

    rule(:national_annex) do
      (str("NA").as(:type) >> supplement.maybe >> str(" to ").ignore).as(:national_annex)
    end

    rule(:translation) do
      # space >> (match("[A-Z]").repeat(1).as(:translation) >> str(" TRANSLATION"))
      space >> ((str("(") >> match("[A-Za-z]").repeat(1).as(:translation) >>
        (space >> (str("Translation") | str("version"))).maybe >> str(")")) |
        (match("[A-Z]").repeat(1).as(:translation) >> str(" TRANSLATION"))
      )
    end

    rule(:pdf) do
      space >> str("PDF").as(:pdf)
    end

    rule(:second_number) do
      str("/") >> digits.as(:second_number)
    end

    rule(:identifier) do
      str("BSI ").maybe >> type >> space >>
        (
          (digits.as(:number) >> second_number.maybe >> part.maybe >> (space >> edition).maybe >>
            (space? >> str(":") >> year >> (dash >> month_digits.as(:month)).maybe).maybe) |
            # exclude expert_commentary and translation from adopted scope
            (expert_commentary.absent? >> translation.absent? >> space? >>
              match("[^+ ]").repeat(1)).repeat.as(:adopted)
        ) >> supplement.maybe >> expert_commentary.maybe >> tracked_changes.maybe >> translation.maybe >> pdf.maybe
    end

    rule(:root) { identifier }
  end
end
