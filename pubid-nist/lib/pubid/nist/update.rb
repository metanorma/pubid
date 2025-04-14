module Pubid::Nist
  class Update < Pubid::Core::Entity
    attr_accessor :number, :year, :month

    def initialize(number: nil, year: nil, month: nil)
      @number = number || 1
      @year = year&.to_s&.length == 2 ? "19#{year}" : year

      if month
        date = Date.parse("01/#{month}/#{@year}")
        @month = date.month
      end
    end
  end
end
