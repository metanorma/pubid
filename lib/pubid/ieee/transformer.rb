module Pubid::Ieee
  class Transformer < Parslet::Transform
    rule(month: simple(:month), year: simple(:year)) do |date|
      update_month_year(date[:month], date[:year])
    end

    rule(month: simple(:month), year: simple(:year), day: simple(:day)) do |date|
      update_month_year(date[:month], date[:year]).merge({ day: date[:day] })
    end

    rule(revision_identifier: subtree(:revision)) do |data|
      Identifier.new(**data[:revision])
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
  end
end
