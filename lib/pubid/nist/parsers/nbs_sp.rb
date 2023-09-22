module Pubid::Nist
  module Parsers
    class NbsSp < Default
      rule(:part_prefixes) do
        str("pt") | str("p") | str("P")
      end

      rule(:volume) do
        str("v") >> (match('[\da-z-]').repeat(1) >> match("[A-Z]").repeat).as(:volume)
      end
    end
  end
end
