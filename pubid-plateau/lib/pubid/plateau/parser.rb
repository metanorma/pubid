module Pubid::Plateau
  class Parser < Pubid::Core::Parser
    rule(:annex) do
      (dash | str("_")) >> digits.as(:annex)
    end

    rule(:edition) do
      space >> str("第") >> (digits >> str(".") >> digits).as(:edition) >> str("版")
    end

    rule(:type) do
      (str("Handbook") | str("Technical Report")).as(:type)
    end

    # PLATEAU Handbook #00 第1.0版
    rule(:number) do
      str("#") >> digits.as(:number)
    end

    # ETSI ETR 299-1 ed.1 (1996-09)
    # ETSI ETR 298 ed.1 (1996-09)
    #
    rule(:identifier) do
      str("PLATEAU") >> space >> type >> space >>
        number >> annex.maybe >> edition.maybe
    end

    rule(:root) { identifier }
  end
end
