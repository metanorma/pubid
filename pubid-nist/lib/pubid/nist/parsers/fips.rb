module Pubid::Nist
  module Parsers
    class Fips < Default
      rule(:edition) do
        str("-") >> (
          (month_letters.as(:edition_month) >> year_digits.as(:edition_year)) |
            year_digits.as(:edition_year) |
          (month_letters.as(:edition_month) >> match('\d').repeat(2, 2).as(:edition_day) >>
            str("/") >> year_digits.as(:edition_year))
        ) |
        (str("e") >> year_digits.as(:edition_year) >> month_digits.as(:edition_month).maybe)
      end
    end
  end
end
