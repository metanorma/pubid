module NistPubid
  module Parsers
    class NbsMp < Default
      rule(:edition) do
        (str("e") >> digits.as(:edition)) | (str("(") >> digits.as(:edition) >> str(")"))
      end
    end
  end
end
