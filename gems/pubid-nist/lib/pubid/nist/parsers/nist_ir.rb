module Pubid::Nist
  module Parsers
    class NistIr < Default
      rule(:number_suffix) { match("[abcA-Z]") }

      rule(:revision) do
        str("r") >> (digits | month_letters >> year_digits).as(:revision)
      end

      rule(:report_number) do
        (digits.as(:first_report_number) >>
          str("-") >> year_digits.as(:edition_year)) |
          first_report_number >> (str("-") >>
            ((digits | match("[aAB]") | str("CAS") | str("FRA")) >>
              # for extra number for NIST IR 85-3273-10
              (str("-") >> digits).maybe).as(:second_report_number)).maybe
      end

      rule(:revision) do
        str("r") >>
          ((digits.as(:month) >> str("/") >> digits.as(:year)).as(:update) |
            (month_letters.as(:month) >> year_digits.as(:year)).as(:update) |
            digits.as(:revision) |
            str("").as(:revision))
      end
    end
  end
end

