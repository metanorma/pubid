module NistPubid
  module Parsers
    class NbsCsm < Default
      rule(:report_number) do
        (str("v") >> match('\d').repeat(1).as(:first_report_number) >>
          str("n") >> match('\d').repeat(1).as(:second_report_number)) |
          match('\d').repeat(1).as(:first_report_number)
      end
    end
  end
end
