module Pubid::Ccsds
  class Parser < Pubid::Core::Parser

    rule(:book_color) do
      dash >> match["BGMYOR"].as(:book_color)
    end

    rule(:edition) do
      dash >> (digits >> (dot >> digits).maybe).as(:edition)
    end

    rule(:part) do
      (dot >> digits.as(:part)).repeat(1)
    end

    rule(:series) do
      match["A-Z"].as(:series)
    end

    rule(:retired) do
      str("-S").as(:retired)
    end

    rule(:corrigendum) do
      space >> str("Cor. ") >> digits.as(:number).as(:corrigendum)
    end

    rule(:language) do
      space >> dash >> space >> words.as(:language) >> space >> str("Translated")
    end

    rule(:identifier) do
      str("CCSDS") >> space >> series.maybe >> digits.as(:number) >> part >>
        book_color >> edition.maybe >> retired.maybe >> corrigendum.maybe >> language.maybe
    end

    rule(:root) { identifier }
  end
end
