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

      edition = serie.parse_edition(code)
      return new(**edition) unless edition.nil?

      nil
    end
  end
end
