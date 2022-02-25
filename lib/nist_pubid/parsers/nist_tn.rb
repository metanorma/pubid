module NistPubid
  module Parsers
    class NistTn < Default
      rule(:report_number) do
        first_report_number
      end

      rule(:edition_prefixes) do
        str("-") | str("e")
      end
    end
  end
end
