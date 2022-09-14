module Pubid::Iso
  class Stage
    attr_accessor :abbr, :harmonized_code

    STAGES = { PWI: "00.00",
               NP: "10.00",
               AWI: "20.00",
               WD: "20.20",
               CD: "30.00",
               DIS: "40.00",
               FDIS: "50.00",
               PRF: "50.00",
               IS: "60.00" }.freeze

    # @param abbr [String, Symbol] abbreviation eg. :PWI, :WD
    # @param harmonized_code [HarmonizedStageCode]
    def initialize(abbr: nil, harmonized_code: nil)
      @abbr = abbr
      @harmonized_code = harmonized_code

      if harmonized_code
        # @abbr = STAGES.select { |k,v| v == @harmonized_code.to_s }.first&.first
        @abbr ||= STAGES.key(@harmonized_code.to_s)
      end

      if abbr
        raise Errors::CodeInvalidError, "#{abbr} is not valid stage" unless STAGES.key?(abbr.to_sym)

        @harmonized_code ||= HarmonizedStageCode.new(*STAGES[abbr.to_sym].split("."))
      end
    end
  end
end
