module Pubid::Nist
  module Parsers
    class Crpl < Default
      rule(:first_report_number) do
        (digits >> (str("-m") | str("-M")).maybe).as(:first_report_number)
      end

      rule(:part) do
        (str("_") | str("pt")) >> (digits >> str("-") >> digits).as(:part)
      end

      rule(:supplement) do
        str("A").as(:supplement)
      end
    end
  end
end
