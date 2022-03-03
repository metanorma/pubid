module Pubid::Nist
  module Parsers
    class NbsTn < Default
      rule(:second_report_number) do
        (digits_with_suffix | str("A")).as(:second_report_number)
      end
    end
  end
end
