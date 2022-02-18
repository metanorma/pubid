module NistPubid
  module Parsers
    class NistTn < Default
      rule(:report_number) do
        match('\d').repeat(1).as(:first_report_number)
      end

      rule(:edition) do
        str("-") >> match('\d').repeat(1).as(:edition)
      end
    end
  end
end
