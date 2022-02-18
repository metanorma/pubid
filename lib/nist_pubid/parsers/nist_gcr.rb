module NistPubid
  module Parsers
    class NistGcr < Default
      rule(:report_number) do
        (match('\d').repeat(1) >>
          str("-") >> match('\d').repeat(1) >> (str("-") >> match('\d').repeat(1)).maybe).as(:report_number)
      end

      rule(:volume) do
        str("v") >> (match('\d').repeat(1) >> match('[A-Z]').repeat).as(:volume)
      end
    end
  end
end
