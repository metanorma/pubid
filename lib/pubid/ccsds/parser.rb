module Pubid::Ccsds
  class Parser < Pubid::Core::Parser

    rule(:book_color) do
      dash >> match["BGMYO"].as(:book_color)
    end

    rule(:edition) do
      dash >> digits.as(:edition)
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

    rule(:identifier) do
      str("CCSDS") >> space >> series.maybe >> digits.as(:number) >> part >>
        book_color >> edition >> retired.maybe >> corrigendum.maybe
    end

    rule(:root) { identifier }
  end
end
