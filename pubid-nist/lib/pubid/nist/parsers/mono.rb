module Pubid::Nist
  module Parsers
    class Mono < Default
      rule(:number_suffix) { match("[a-zA-Z]") }
    end
  end
end
