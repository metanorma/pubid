module Pubid::Nist
  module Parsers
    class Rpt < Default
      rule(:report_number) do
        (month_letters >>
          str("-") >> (month_letters >> year_digits)).as(:report_number) |
          (digits >> str("-") >> (digits | str("A"))).as(:report_number) |
          (digits >> (str("a") | str("b")).maybe).as(:report_number) |
          (str("ADHOC") | str("div9")).as(:report_number)
      end
    end
  end
end
