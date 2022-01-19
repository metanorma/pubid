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

    def self.parse(code, serie = nil)
      serie = Serie.parse(code) if serie.nil?

      return nil if serie.nil?

      if ["NIST HB 135-2020", "NIST.HB.135-2020"].include?(code)
        return new(sequence: "2020", parsed: "-2020")
      end

      edition = serie.class::EDITION_REGEXP.match(code)
      if edition
        parsed = edition.captures.join.to_s
      end

      return nil if edition.nil? || edition.captures.compact.empty?

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
