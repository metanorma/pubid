module NistPubid
  module Parsers
    class NbsCrpl < Default
      rule(:first_report_number) do
        (digits >> str("-m").maybe).as(:first_report_number)
      end

      rule(:part) do
        str("_") >> (digits >> str("-") >> digits).as(:part)
      end

      rule(:supplement) do
        str("A").as(:supplement)
      end
    end
  end
end
