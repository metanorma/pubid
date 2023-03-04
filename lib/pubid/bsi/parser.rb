module Pubid::Bsi
  class Parser < Pubid::Core::Parser
    rule(:part) do
      str("-") >> digits.as(:part)
    end

    rule(:identifier) do
      str("BS") >> space >> digits.as(:number) >> part.maybe >> (space? >> str(":") >> year).maybe
    end

    rule(:root) { identifier }
  end
end
