module Pubid::Ieee
  class Parser < Parslet::Parser
    rule(:digits) do
      match('\d').repeat(1)
    end

    rule(:year) do
      match('\d').repeat(4, 4)
    end

    rule(:organization) do
      str("IEEE") | str("AIEE")
    end

    rule(:identifier) do
      organization >> str(" ") >> (str("No") | str("no")) >> (str(".") | str(" ")) >>
        str(" ").maybe >>
        (digits | match("[A-Z]")).repeat(1).as(:number) >> str("-") >> year.as(:year)
    end

    rule(:root) { identifier }
  end
end
