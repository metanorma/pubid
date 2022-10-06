module Pubid::Iso
  class Stage
    attr_accessor :abbr, :harmonized_code

    STAGES = { PWI: "00.00",
               NP: "10.00",
               AWI: %w[20.00 10.99],
               WD: %w[20.20 20.60 20.98 20.99],
               CD: "30.00",
               DIS: "40.00",
               FDIS: "50.00",
               PRF: "60.00",
               IS: "60.60" }.freeze


    STAGE_NAMES = {
      FDIS: "Final Draft International Standard",
      DIS: "Draft International Standard",
      WD: "Working Draft",
      PWI: "Preliminary Work Item",
      NP: "New Proposal",
      CD: "Committee Draft",
      PRF: "Proof of a new International Standard",
      IS: "International Standard",
    }.freeze

    STAGE_NAMES_SHORT = {
      FDIS: "Final Draft",
      DIS: "Draft",
      WD: "Working Draft",
      PWI: "Preliminary Work Item",
      NP: "New Proposal",
      CD: "Committee Draft",
      PRF: "Proof of a new International Standard",
      IS: "International Standard",
    }.freeze

    # @param abbr [String, Symbol] abbreviation eg. :PWI, :WD
    # @param harmonized_code [String, Float, HarmonizedStageCode]
    def initialize(abbr: nil, harmonized_code: nil)
      @abbr = abbr&.to_s

      if harmonized_code
        @harmonized_code = if harmonized_code.is_a?(HarmonizedStageCode)
                             harmonized_code
                           else
                             HarmonizedStageCode.new(*harmonized_code.to_s.split("."))
                           end
        @abbr ||= lookup_abbr(@harmonized_code.to_s) || lookup_abbr("#{@harmonized_code.stage}.00")
      end

      if abbr
        raise Errors::StageInvalidError, "#{abbr} is not valid stage" unless STAGES.key?(abbr.to_sym)

        @harmonized_code ||= HarmonizedStageCode.new(*lookup_code(abbr).split("."))
      end
    end

    # Lookup for abbreviated code by numeric stage code
    # @param lookup_code [String] stage code, e.g. "00.00", "20.20"
    def lookup_abbr(lookup_code)
      STAGES.each do |abbr, codes|
        case codes
        when Array
          codes.each do |code|
            return abbr if code == lookup_code
          end
        when lookup_code
          return abbr
        end
      end

      nil
    end

    def lookup_code(lookup_abbr)
      code = STAGES[lookup_abbr.to_sym]
      code.is_a?(Array) ? code.first : code
    end

    def self.parse(stage)
      if /\A[\d.]+\z/.match?(stage)
        Stage.new(harmonized_code: stage)
      else
        raise Errors::StageInvalidError unless stage.is_a?(Symbol) || stage.is_a?(String)

        Stage.new(abbr: stage)
      end
    end

    # Compares one stage with another
    def ==(other)
      other&.harmonized_code == harmonized_code
    end

    # Return stage name, eg. "Draft International Standard" for "DIS"
    def name
      STAGE_NAMES[abbr.to_sym]
    end

    # Return short stage name, eg. "Draft" for "DIS"
    def short_name
      STAGE_NAMES_SHORT[abbr.to_sym]
    end
  end
end
