module Pubid::Ieee
  class Parser < Parslet::Parser
    rule(:digits) do
      match('\d').repeat(1)
    end

    rule(:year) do
      match('\d').repeat(4, 4)
    end

    rule(:organization) do
      str("IEEE") | str("AIEE") | str("ANSI")
    end

    rule(:number) do
      (digits | match("[A-Z]")).repeat(1).as(:number)
    end

    rule(:part) do
      (str(".") | str("-")) >> (digits | match("[A-Z]")).repeat(1).as(:part)
    end

    rule(:subpart) do
      (str(".") | str("-")) >> digits
    end

    rule(:type) do
      str("Std") | str("STD") | str("Standard") | str("Draft Std") | str("Draft")
    end

    rule(:identifier) do
      organization.as(:publisher) >> str(" ") >> (type.as(:type) >> str(" ")).maybe >> (
        (str("No") | str("no")) >> (str(".") | str(" "))
      ).maybe >> str(" ").maybe >>
      number >> (part >> subpart.repeat.as(:subpart)).maybe >> (str("-") >> year.as(:year)).maybe
    end

    rule(:root) { identifier }
  end
end
