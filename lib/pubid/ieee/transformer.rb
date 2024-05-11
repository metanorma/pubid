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

    rule(iso_identifier: subtree(:iso_identifier)) do |data|
      # keep identifier in ISO format if it have ISO format Amendment in "supplements"
      if data[:iso_identifier][:publisher] == "IEEE" && !data[:iso_identifier].key?(:supplements)
        # convert ISO identifier to IEEE identifier if publisher == "IEEE"
        if data[:iso_identifier][:part]
          data[:iso_identifier][:part] = ".#{data[:iso_identifier][:part]}"
        end
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
