module Pubid::Ieee
  class Transformer < Parslet::Transform
    rule(month: simple(:month)) do |month|
      { month: update_month(month[:month]) }
    end

    rule(year: subtree(:year)) do |data|
      { year: update_year(data[:year].is_a?(Array) ? data[:year].first : data[:year]) }
    end

    rule(identifier: subtree(:identifier)) do |data|
      if data[:identifier].is_a?(Parslet::Slice)
        Identifier::Base.transform(Identifier.convert_parser_parameters(**Parser.new.iso_or_ieee_identifier.parse(data[:identifier].to_s)))
      else
        Identifier::Base.transform(Identifier.convert_parser_parameters(**data[:identifier]))
      end
    end

    rule(iso_identifier: subtree(:iso_identifier)) do |data|
      # apply transformer to :iso_identifier => :month
      if data[:iso_identifier].key?(:month)
        data[:iso_identifier][:month] = update_month(data[:iso_identifier][:month])
      end
      # keep identifier in ISO format if it have ISO format Amendment in "supplements"
      if (data[:iso_identifier][:publisher] == "IEEE" ||
        (data[:iso_identifier][:copublisher].is_a?(Array) && data[:iso_identifier][:copublisher].include?("IEEE") ||
          data[:iso_identifier][:copublisher] == "IEEE")) && !data[:iso_identifier].key?(:supplements) &&
          !data[:iso_identifier].key?(:type)
        if data[:iso_identifier].key?(:stage)
          data[:iso_identifier][:draft] = { version: data[:iso_identifier][:stage] }
          data[:iso_identifier][:stage] = nil
        end
        data[:iso_identifier]
      else
        if data[:iso_identifier][:corrigendum]
          corrigendum = data[:iso_identifier][:corrigendum]
          data[:iso_identifier][:supplements] = [
            { type: "cor",
              year: corrigendum[:year],
              number: corrigendum[:version] },
          ]
          data[:iso_identifier].delete(:corrigendum)
        end

        # type status cannot be rendered in pubid-iso
        data[:iso_identifier].delete(:type_status)
        data
      end
    end

    rule(stage: simple(:stage)) do |data|
      { draft: { version: data[:stage] } }
    end

    rule(stage: simple(:stage), iteration: simple(:iteration)) do |data|
      { draft: { version: data[:stage] }, iteration: data[:iteration] }
    end

    rule(stage: simple(:stage), iteration: simple(:iteration),
         part: simple(:part)) do |data|
      { draft: { version: data[:stage] }, iteration: data[:iteration] }.merge(part: data[:part])
    end

    def self.update_year(year)
      if year.length == 2
        case year.to_i
        when 0..25 then "20#{year}"
        when 26..99 then "19#{year}"
        end
      else
        year
      end
    end

    def self.update_month(month)
      return month if month.is_a?(Integer)

      # add year when only month digits provided to avoid parsing digits as year
      Date.parse("1999/#{month}").month
    end

    def self.update_month_year(month, year)
      { year: update_year(year),
        month: update_month(month) }
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
