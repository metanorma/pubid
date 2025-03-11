module Pubid::Core
  class Parser < Parslet::Parser
    rule(:space) { str(" ") }
    rule(:space?) { space.maybe }

    rule(:digits) do
      match('\d').repeat(1)
    end

    rule(:year) do
      match('\d').repeat(4, 4).as(:year)
    end

    rule(:comma) { str(", ") }
    rule(:comma?) { comma.maybe }
    rule(:comma_space) { comma | space }
    rule(:dash) { str("-") }
    rule(:dot) { str(".") }
    rule(:words_digits) { match('[\dA-Za-z]').repeat(1) }
    rule(:words) { match("[A-Za-z]").repeat(1) }
    rule(:words?) { words.maybe }
    rule(:year_digits) { (str("19") | str("20")) >> match('\d').repeat(2, 2) }

    rule(:month_digits) do
      match('\d').repeat(2, 2)
    end

    rule(:day_digits) do
      match('\d').repeat(2, 2)
    end

    rule(:originator) do
      organization.as(:publisher) >>
        (space? >> str("/") >> organization.as(:copublisher)).repeat
    end

    rule(:comma_month_year) do
      comma >> words.as(:month) >> space >> year_digits.as(:year)
    end

    rule(:year_month) do
      year_digits >> dash >> month_digits
    end

    def array_to_str(array)
      array.reduce(str(array.first)) do |acc, value|
        acc | str(value)
      end
    end
  end
end
