module NistPubid
  module Parsers
    class NistSp < Default
      rule(:version) do
        ((str("ver") >> match('\d').repeat(1).as(:version)) |
          (str("v") >> (match('\d') >> str(".") >> match('\d') >> str(".") >> match('\d')).as(:version)))
      end

      rule(:first_report_number) do
        (match('\d').repeat(1) >> (str("GB") | str("a")).maybe)
      end

      rule(:report_number) do
        # (\d+-\d{1,3}).as(:report_number)
        # (\d+-\d{4}).as(:report_number) when first number is 250
        # (\d+).as(:report_number)-(\d{4}).as(:edition)
        # or \d-\d-(\d).as(:revision)
        (first_report_number.capture(:first_number).as(:first_report_number) >>
          (str("-") >>
            dynamic do |_source, context|
              # consume 4 numbers or any amount of numbers
              # for document ids starting from 250
              (if context.captures[:first_number] == "250"
                 match('\d').repeat(1)
               else
                 # skip edition numbers (parse only if have not 4 numbers)
                 match('\d').repeat(4, 4).absent? >> match('\d').repeat(1)
               end >> match["[A-Zabcd]"].maybe
                # parse last number as edition if have 4 numbers
              ) | (str("NCNR") | str("PERMIS") | str("BFRL"))
            end.as(:second_report_number)
            # parse A-Z and abcd as part of report number
          ).maybe
        )
      end

      rule(:edition) do
        ((str("e") >> match("\\d").repeat(4,4).as(:edition_year)) | (str("-") >> match("\\d").repeat(4,4).as(:edition_year)) |
          (str("e") >> match("\\d").repeat(1).as(:edition)))
      end

      rule(:revision) do
        ((str("rev") | str("r") | str("-")) >> (match('\d').repeat(1) >> match("[a-z]").maybe).as(:revision)) |
          (str("r") >> match("[a-z]").as(:revision))
      end
    end
  end
end
