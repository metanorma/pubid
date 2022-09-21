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
    # @param harmonized_code [String, Float, HarmonizedStageCode]
    def initialize(abbr: nil, harmonized_code: nil)
      @abbr = abbr

      if harmonized_code
        @harmonized_code = if harmonized_code.is_a?(HarmonizedStageCode)
                             harmonized_code
                           else
                             HarmonizedStageCode.new(*harmonized_code.to_s.split("."))
                           end
        @abbr ||= STAGES.key(@harmonized_code.to_s) || STAGES.key("#{@harmonized_code.stage}.00")
      end

      if abbr
        raise Errors::CodeInvalidError, "#{abbr} is not valid stage" unless STAGES.key?(abbr.to_sym)

        @harmonized_code ||= HarmonizedStageCode.new(*STAGES[abbr.to_sym].split("."))
      end
    end

    def self.parse(stage)
      if /\A[\d.]+\z/.match?(stage)
        Stage.new(harmonized_code: stage)
      else
        raise Errors::CodeInvalidError unless stage.is_a?(Symbol) || stage.is_a?(String)

        Stage.new(abbr: stage)
      end
    end
  end
end
