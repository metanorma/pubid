module Pubid::Nist
  module Parsers
    class NbsLc < Default
      rule(:supplement) do
        (str("supp") | str("sup")) >>
          ((str("").as(:supplement) >> (digits.as(:month) >> str("/") >> digits.as(:year)).as(:update)) |
          match('\d').repeat.as(:supplement))
      end

      rule(:revision) do
        str("r") >>
          ((digits.as(:month) >> str("/") >> digits.as(:year)).as(:update) |
            digits.as(:revision))
      end

      # suffixes for LCIRC 378
      rule(:number_suffix) { match("[abcdefghA-Z]") }
    end
  end
end

