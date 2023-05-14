module Pubid::Ieee
  class Transformer < Parslet::Transform
    rule(month: simple(:month), year: simple(:year)) do |date|
      update_month_year(date[:month], date[:year])
    end

    rule(month: simple(:month), year: simple(:year), day: simple(:day)) do |date|
      update_month_year(date[:month], date[:year]).merge({ day: date[:day] })
    end

    rule(identifier: subtree(:identifier)) do |data|
      if data[:identifier].is_a?(Parslet::Slice)
        Identifier::Base.transform(Identifier.convert_parser_parameters(**Parser.new.iso_or_ieee_identifier.parse(data[:identifier].to_s)))
      else
        Identifier::Base.transform(Identifier.convert_parser_parameters(**data[:identifier]))
      end
    end

    def self.update_month_year(month, year)
      { year: if year.length == 2
                case year.to_i
                when 0..25 then "20#{year}"
                when 26..99 then "19#{year}"
                end
              else
                year
              end,
        month: Date.parse(month).strftime("%B") }
    end

    rule(type: simple(:type)) do
      { type: case type
        when "Standard"
          :std
        else
          type
        end }
    end
  end
end
