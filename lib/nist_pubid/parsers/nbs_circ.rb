module NistPubid
  module Parsers
    class NbsCirc < Default
      rule(:revision) do
        ((str("rev") >> (match("[A-Za-z]").repeat(1) >> match('\d').repeat(4,4)).as(:revision)) |
          (str("r") >> match('\d').repeat(1).as(:revision))
        )
      end

      rule(:report_number) do
        (match('\d').repeat(1).as(:first_report_number) >> edition.maybe >>
          (str("-") >> (match('\d').repeat(1) >> match("[aA-Z]").maybe).as(:second_report_number)).maybe)
      end

      rule(:edition) do
        (str("sup") >> str("").as(:supplement) >>
          (match('[A-Za-z]').repeat(3, 3).as(:edition_month) >> match('\d').repeat(4,4).as(:edition_year))) |
          ((str("e") | str("-")) >> match('\d').repeat(1).as(:edition)) #  | str("-")
      end
    end
  end
end
