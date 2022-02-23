module NistPubid
  module Parsers
    class NbsIr < Default
      rule(:report_number) do
        (digits.as(:first_report_number) >>
          (str("-") >> (match('[\d.]').repeat(1) >> number_suffix.maybe)
                         .as(:second_report_number)).maybe
        ).capture(:report_number) >>
          dynamic do |_source, context|
            report_number = context.captures[:report_number]
              .values_at(:first_report_number, :second_report_number).join("-")
            if %w[74-577 77-1420].include?(report_number)
              str("-") >> match('\d').as(:volume)
            else
              str("-") >> digits.as(:part)
            end
          end.maybe
      end
    end
  end
end
