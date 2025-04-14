module Pubid::Nist
  module Parsers
    class Csm < Default
      rule(:identifier) do
        (str(" ") | str(".")) >> report_number.maybe >> parts.repeat.as(:parts)
      end

      rule(:part_prefixes) { str("n") | str("pt") }
    end
  end
end
