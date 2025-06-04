module Pubid::Nist
  module Parsers
    class NbsIr < Default
      rule(:second_report_number) do
        (match('[\d.]').repeat(1) >> number_suffix.maybe).as(:second_report_number)
      end

      rule(:report_number) do
        (first_report_number >>
          (str("-") >> second_report_number).maybe
        ).capture(:report_number) >>
          # parse last part as volume for specific document numbers
          dynamic do |_source, context|
            report_number = context.captures[:report_number]
              .values_at(:first_report_number, :second_report_number).join("-")
            if %w[74-577 77-1420].include?(report_number)
              str("-") >> match('\d').as(:volume)
            else
              self
            end
          end.maybe
      end

      rule(:part_prefixes) do
        str("pt") | str("p") | str("-")
      end
    end
  end
end
