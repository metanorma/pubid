module Pubid::Ieee
  class Parser < Parslet::Parser
    rule(:digits) do
      match('\d').repeat(1)
    end

    rule(:year) do
      match('\d').repeat(4, 4)
    end

    rule(:identifier) do
      str("IEEE No") >> (str(" ") | str(". ")) >> digits.as(:number) >> str("-") >> year.as(:year)
    end

    rule(:root) { identifier }
  end
end
