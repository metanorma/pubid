module Pubid::Ccsds
  class Parser < Pubid::Core::Parser

    rule(:type) do
      dash >> match["BGMYO"].as(:type)
    end

    rule(:edition) do
      dash >> digits.as(:edition)
    end

    rule(:part) do
      (dot >> digits.as(:part)).repeat(1)
    end

    rule(:identifier) do
      str("CCSDS") >> space >> digits.as(:number) >> part >> type >> edition
    end

    rule(:root) { identifier }
  end
end
