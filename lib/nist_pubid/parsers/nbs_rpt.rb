module NistPubid
  module Parsers
    class NbsRpt < Default
      rule(:report_number) do
        (match('[A-Za-z]').repeat(3, 3) >>
          str("-") >> (match('[A-Za-z]').repeat(3, 3) >> match('\d').repeat(4, 4))).as(:report_number) |
          (digits >> str("-") >> digits).as(:report_number) |
          (str("ADHOC") | str("div9") | match('\d').repeat(1)).as(:report_number)
      end
    end
  end
end
