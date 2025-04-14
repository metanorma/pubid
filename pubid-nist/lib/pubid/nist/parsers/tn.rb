module Pubid::Nist
  module Parsers
    class Tn < Default
      # rule(:report_number) do
      #   first_report_number
      # end

      rule(:edition_prefixes) do
        str("-") | str("e")
      end

      rule(:second_report_number) do
        year_digits.absent? >> (digits_with_suffix | str("A")).as(:second_report_number)
      end
    end
  end
end
