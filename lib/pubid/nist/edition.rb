module Pubid::Nist
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
      result = (@sequence && [@sequence]) || []
      if @day
        result << Date.new(@year, @month, @day).strftime("%Y%m%d")
      elsif @month
        result << Date.new(@year, @month).strftime("%Y%m")
      elsif @year
        result << Date.new(@year).strftime("%Y")
      end

      result.join("-")
    end
  end
end
