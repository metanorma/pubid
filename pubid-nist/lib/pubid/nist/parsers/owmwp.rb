module Pubid::Nist
  module Parsers
    class Owmwp < Default
      rule(:report_number) do
        digits_with_suffix.as(:first_report_number) >>
          (str("-") >> (digits_with_suffix >> (str("-") >> digits_with_suffix).maybe)
                         .as(:second_report_number)).maybe
      end
    end
  end
end
