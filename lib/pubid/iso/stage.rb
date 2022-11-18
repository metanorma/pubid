module Pubid::Iso
  class Stage
    attr_accessor :abbr, :harmonized_code

    STAGES = { PWI: %w[00.00 00.20 00.60 00.98 00.99],
               NP: %w[10.00 10.20 10.60 10.98 10.92],
               AWI: %w[20.00 10.99],
               WD: %w[20.20 20.60 20.98 20.99],
               CD: %w[30.00 30.20 30.60 30.92 30.98 30.99],
               PRF: "60.00" }.freeze


    STAGE_NAMES = {
      WD: "Working Draft",
      PWI: "Preliminary Work Item",
      NP: "New Proposal",
      CD: "Committee Draft",
      PRF: "Proof of a new International Standard",
    }.freeze

    # @param abbr [String, Symbol] abbreviation eg. :PWI, :WD
    # @param harmonized_code [String, Float, HarmonizedStageCode]
    def initialize(abbr: nil, harmonized_code: nil)
      @abbr = abbr&.to_s

      if harmonized_code
        @harmonized_code = if harmonized_code.is_a?(HarmonizedStageCode)
                             harmonized_code
                           else
                             HarmonizedStageCode.new(harmonized_code)
                           end
        @abbr ||= lookup_abbr(@harmonized_code.stages)
        # unless @harmonized_code.fuzzy?
        #   @abbr ||= lookup_abbr(@harmonized_code.to_s) || lookup_abbr("#{@harmonized_code.stage}.00")
        # end
      end

      if abbr
        raise Errors::StageInvalidError, "#{abbr} is not valid stage" unless STAGES.key?(abbr.to_sym)

        @harmonized_code ||= HarmonizedStageCode.new(lookup_code(abbr))
      end
    end

    # Lookup for abbreviated code by numeric stage code
    # @param lookup_code [String, Array] stage code or array of stage codes,
    #   e.g. "00.00", "20.20", ["00.00", "00.20"]
    def lookup_abbr(lookup_code)
      lookup_code = lookup_code.first if lookup_code.is_a?(Array) && lookup_code.count == 1

      STAGES.each do |abbr, codes|
        case codes
        when Array
          if lookup_code.is_a?(Array)
            return abbr if codes == lookup_code
          else
            return abbr if codes.include?(lookup_code)
          end
          # codes.each do |code|
          #   return abbr if code == lookup_code
          # end
        when lookup_code
          return abbr
        end
      end

      nil
    end

    def lookup_code(lookup_abbr)
      STAGES[lookup_abbr.to_sym]
      # code.is_a?(Array) ? code.first : code
    end

    def self.parse(stage)
      if /\A[\d.]+\z/.match?(stage)
        Stage.new(harmonized_code: stage)
      else
        raise Errors::StageInvalidError unless stage.is_a?(Symbol) || stage.is_a?(String) || stage.is_a?(Parslet::Slice)

        Stage.new(abbr: stage.to_s)
      end
    end

    # @return [Boolean] true if stage exists
    def self.has_stage?(stage)
      if stage.is_a?(Stage)
        STAGES.key?(stage.abbr.to_sym)
      else
        STAGES.key?(stage.to_sym) || /\A[\d.]+\z/.match?(stage)
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

    # @param with_prf [Boolean]
    # @return [Boolean] false if there are output for abbreviation should be produced
    def empty_abbr?(with_prf: false)
      return true if abbr == "PRF" && !with_prf

      abbr.nil?
    end

    def to_s(opts)
      abbr unless empty_abbr?(**opts)
    end
  end
end
