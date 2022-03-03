module Pubid::Nist
  module Parsers
    class NbsLc < Default
      rule(:supplement) do
        (str("supp") | str("sup")) >>
          ((str("").as(:supplement) >> digits.as(:update_month) >> str("/") >> digits.as(:update_year)) |
          match('\d').repeat.as(:supplement))
      end

      rule(:revision) do
        str("r") >>
          ((digits.as(:update_month) >> str("/") >> digits.as(:update_year)) |
            digits.as(:revision))
      end

      # suffixes for LCIRC 378
      rule(:number_suffix) { match("[abcdefghA-Z]") }
    end
  end
end

