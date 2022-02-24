module NistPubid
  module Parsers
    class NistIr < Default
      rule(:number_suffix) { match("[abcA-Z]") }

      rule(:revision) do
        str("r") >> (digits | month_letters >> year_digits).as(:revision)
      end

      rule(:report_number) do
        (year_digits.as(:first_report_number) >>
          str("-") >> year_digits.as(:edition_year)) |
          digits_with_suffix.as(:first_report_number) >> (str("-") >>
            ((digits | match("[aAB]") | str("CAS") | str("FRA")) >>
              # for extra number for NIST IR 85-3273-10
              (str("-") >> digits).maybe).as(:second_report_number)).maybe
      end

      rule(:revision) do
        str("r") >>
          ((digits.as(:update_month) >> str("/") >> digits.as(:update_year)) |
            (month_letters.as(:update_month) >> year_digits.as(:update_year)) |
            digits.as(:revision) |
            str("").as(:revision))
      end
    end
  end
end

