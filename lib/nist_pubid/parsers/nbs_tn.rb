module NistPubid
  module Parsers
    class NbsTn < Default
      rule(:report_number) do
        digits_with_suffix.as(:first_report_number) >>
          (str("-") >> (digits_with_suffix | str("A")).as(:second_report_number)).maybe
      end
    end
  end
end
