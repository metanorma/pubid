module Pubid::Nist
  module Parsers
    class Gcr < Default
      rule(:report_number) do
        (digits >>
          str("-") >> digits >> (str("-") >> digits).maybe).as(:report_number)
      end

      rule(:volume) do
        str("v") >> (digits >> match('[A-Z]').repeat).as(:volume)
      end
    end
  end
end
