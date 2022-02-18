module NistPubid
  module Parsers
    class NbsMp < Default
      rule(:edition) do
        ((str("e") >> match('\d').repeat(1).as(:edition)) |
          (str("(") >> match('\d').repeat(1).as(:edition) >> str(")")))
      end
    end
  end
end
