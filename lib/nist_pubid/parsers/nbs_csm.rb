module NistPubid
  module Parsers
    class NbsCsm < Default
      rule(:identifier) do
        (str(" ") | str(".")) >> report_number.maybe >> parts.repeat.as(:parts)
      end

      rule(:part_prefixes) { str("n") }
    end
  end
end
