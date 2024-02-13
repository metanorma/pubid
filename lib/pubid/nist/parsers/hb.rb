module Pubid::Nist
  module Parsers
    class Hb < Default
      rule(:number_suffix) { match("[a-zA-Z]") }

      rule(:edition) do
        (str("supp") >> str("").as(:supplement) >>
          (words.as(:edition_month) >> year_digits.as(:edition_year)) |
          str("e") >> year_digits.as(:edition_year)
        )
      end

      rule(:report_number) do
        digits.as(:first_report_number) >> volume.maybe >>
          (str("e") >> digits.as(:edition) >> (str("-") >> digits).maybe |
            str("-") >> year_digits.as(:edition_year) |
            str("-") >> digits.as(:second_report_number) >> str("-") >>  year_digits.as(:edition_year) |
            str("-") >> digits_with_suffix.as(:second_report_number)
          ).maybe
      end
    end
  end
end
