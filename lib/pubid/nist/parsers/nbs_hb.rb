module Pubid::Nist
  module Parsers
    class NbsHb < Default
      # found patterns:
      # 44e2-1955 -> 44e2
      # 146v1-1991
      # 105-1-1990 -> 105-1e1990
      # 111r1977 / 146v1
      # 130-1979 -> 130e1979
      # 105-8 -> 105-8
      # 28supp1957pt1
      # 67suppFeb1965

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
