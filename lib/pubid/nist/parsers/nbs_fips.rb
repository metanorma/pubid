module Pubid::Nist
  module Parsers
    class NbsFips < Default
      rule(:edition) do
        str("-") >> (
          (month_letters.as(:edition_month) >> year_digits.as(:edition_year)) |
            year_digits.as(:edition_year) |
          (month_letters.as(:edition_month) >> match('\d').repeat(2, 2).as(:edition_day) >>
            str("/") >> year_digits.as(:edition_year))
        )
      end
    end
  end
end
