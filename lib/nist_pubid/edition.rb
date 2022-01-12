module NistPubid
  class Edition
    attr_accessor :year, :month, :day, :parsed, :sequence

    def initialize(parsed: nil, year: nil, month: nil, day: nil, sequence: nil)
      @parsed = parsed
      @year = year
      @month = month
      @day = day
      @sequence = sequence
    end

    def to_s
      if @day
        Date.new(@year, @month, @day).strftime("%d%b%Y")
      elsif @month
        Date.new(@year, @month).strftime("%b%Y")
      elsif @year
        Date.new(@year).strftime("%Y")
      else
        @sequence
      end
    end

    def self.parse(code)
      if ["NIST HB 135-2020", "NIST.HB.135-2020"].include?(code)
        return new(sequence: "2020", parsed: "-2020")
      end

      edition = /(?<=NBS\sIR\s80)-(?<sequence>\d{4})/x.match(code)
      if edition
        parsed = edition.to_s
      else
        edition = /(?<=[^a-z])(?<=\.)?(?:\d+-\d+)?
                 (?<prepend>e-?|Ed\.\s|-)
                 (?:(?<year>\d{4})|(?<sequence>\d+)(?!-))/x.match(code)
        if edition
          parsed = edition.captures.join.to_s
        else
          edition = /NBS\sFIPS\s[0-9]+[A-Za-z]*-[0-9]+[A-Za-z]*-([A-Za-z\d]+)|
            NBS\sFIPS\sPUB\s[0-9]+[A-Za-z]*-(?:\d+-)?(?:
              (?<date_with_month>[A-Za-z]{3}\d{4})| # NBS FIPS 107-Mar1985
              (?<date_with_day>[A-Za-z]{3}\d{2}\/\d{4})| # NBS FIPS PUB 11-1-Sep30\/1977
              (?<year>\d{4})
            )|
            (?:NIST|NBS)\sFIPS\sPUB\s[0-9]+[A-Za-z]*-(?<sequence>\d+) # NIST FIPS 140-3
            /x.match(code)
          parsed = "-#{edition.captures.join}" if edition
        end
      end

      return nil unless edition

      if edition.named_captures.key?("date_with_month") && edition[:date_with_month]
        date = Date.parse(edition[:date_with_month])
        new(month: date.month, year: date.year, parsed: "-#{edition.captures.join}")
      elsif edition.named_captures.key?("date_with_day") && edition[:date_with_day]
        date = Date.parse(edition[:date_with_day])
        new(day: date.day, month: date.month, year: date.year, parsed: "-#{edition.captures.join}")
      elsif edition.named_captures.key?("year") && edition[:year]
        new(year: edition[:year].to_i, parsed: parsed)
      else
        new(sequence: edition[:sequence], parsed: parsed)
      end
    end
  end
end
