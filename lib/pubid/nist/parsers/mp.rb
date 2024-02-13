module Pubid::Nist
  module Parsers
    class Mp < Default
      rule(:edition) do
        (str("e") >> digits.as(:edition)) | (str("(") >> digits.as(:edition) >> str(")"))
      end
    end
  end
end
