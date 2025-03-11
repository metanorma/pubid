module Pubid::Nist
  class Edition < Pubid::Core::Entity
    attr_accessor :year, :month, :day, :parsed, :number

    def initialize(parsed: nil, year: nil, month: nil, day: nil, number: nil)
      @parsed = parsed
      @year = year
      @month = month
      @day = day
      @number = number
    end

    def to_s(format: :short)

      if format == :long
        result = (@number && ["Edition #{@number}"]) || []
        if @day
          result << Date.new(@year, @month, @day).strftime("(%B %d, %Y)")
        elsif @month
          result << Date.new(@year, @month).strftime("(%B %Y)")
        elsif @year
          result << Date.new(@year).strftime("(%Y)")
        end
        result.join(" ")
      else
        result = (@number && [@number]) || []
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
end
