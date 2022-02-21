module NistPubid
  module Parsers
    class NbsCirc < Default
      rule(:revision) do
        ((str("rev") >> (letters >> year_digits).as(:revision)) |
          (str("r") >> digits.as(:revision))
        )
      end

      rule(:report_number) do
        (digits.as(:first_report_number) >> edition.maybe >>
          (str("-") >> (digits >> match("[aA-Z]").maybe).as(:second_report_number)).maybe)
      end

      rule(:edition) do
        (str("sup") >> str("").as(:supplement) >>
          (letters.as(:edition_month) >> year_digits.as(:edition_year))) |
          ((str("e") | str("-")) >> (digits.as(:edition) | letters.as(:edition_month) >> year_digits.as(:edition_year)))
      end
    end
  end
end
