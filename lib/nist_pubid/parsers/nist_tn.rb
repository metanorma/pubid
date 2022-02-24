module NistPubid
  module Parsers
    class NistTn < Default
      rule(:report_number) do
        match('\d').repeat(1).as(:first_report_number)
      end

      rule(:edition) do
        (str("-") | str("e")) >> match('\d').repeat(1).as(:edition)
      end
    end
  end
end
