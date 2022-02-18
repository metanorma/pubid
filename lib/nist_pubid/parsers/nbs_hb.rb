module NistPubid
  module Parsers
    class NbsHb < Default
      # found patterns:
      # 44e2-1955 -> 44e2
      # 105-1-1990 -> 105-1e1990
      # 111r1977
      # 130-1979 -> 130e1979
      # 105-8 -> 105-8
      # 28supp1957pt1
      # 67suppFeb1965

      rule(:edition) do
        (str("supp") >> str("").as(:supplement) >>
          (match('[A-Za-z]').repeat(3, 3).as(:edition_month) >> match('\d').repeat(4,4).as(:edition_year)))
      end

      rule(:report_number) do
        match('\d').repeat(1).as(:first_report_number) >>
          (str("e") >> match('\d').repeat(1).as(:edition) >> (str("-") >> match('\d').repeat(1)).maybe |
            str("-") >> match('\d').repeat(4,4).as(:edition_year) |
            str("-") >> match('\d').repeat(1).as(:second_report_number) >> str("-") >>  match('\d').repeat(4,4).as(:edition_year) |
            str("-") >> match('\d').repeat(1).as(:second_report_number)
          ).maybe
      end
    end
  end
end
