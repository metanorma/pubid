module NistPubid
  module Parsers
    class NbsSp < Default
      rule(:part) do
        (str("p") | str("P")) >> match("\\d").as(:part)
      end

      rule(:volume) do
        str("v") >> (match('[\da-z-]').repeat(1) >> match('[A-Z]').repeat).as(:volume)
      end
    end
  end
end
