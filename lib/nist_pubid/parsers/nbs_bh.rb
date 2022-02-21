module NistPubid
  module Parsers
    class NbsBh < Default
      # rule(:report_number) do
      #   (match('\d').repeat(1).as(:first_report_number) >>
      #     (str("-") >> (match('\d').repeat(1) >> match("[aA-Z]").maybe).as(:second_report_number)).maybe)
      # end
    end
  end
end
