module Pubid::Core
  class HarmonizedStageCode
    include Comparable
    # attr_accessor :stage, :substage
    attr_accessor :stages

    DESCRIPTIONS = STAGES_CONFIG["codes_description"]
    DRAFT_STAGES = STAGES_CONFIG["draft_codes"]
    CANCELED_STAGES = STAGES_CONFIG["canceled_codes"]
    PUBLISHED_STAGES = STAGES_CONFIG["published_codes"]
    STAGES_NAMES = STAGES_CONFIG["stage_codes"]
    SUBSTAGES_NAMES = STAGES_CONFIG["substage_codes"]

    # @param stage_or_code [String,Array<String>] stage number or whole harmonized code with substage
    #   or list or stages for fuzzy stages eg. "10", 10, "20.20", ["10.20", "20.20"]
    #   or stage name eg. "proposal", "approval"
    # @param substage [Integer, String] eg. "00", 0
    #   or substage name eg. "registration", "start_of_main_action"
    def initialize(stage_or_code, substage = "00")
      @stages = if stage_or_code.is_a?(Array)
                  stage_or_code
                elsif stage_or_code.is_a?(String) && DESCRIPTIONS.key?(stage_or_code)
                  [stage_or_code]
                  # when stage is stage name
                elsif STAGES_NAMES.key?(stage_or_code.to_s)
                  ["#{STAGES_NAMES[stage_or_code.to_s]}.#{SUBSTAGES_NAMES[substage.to_s]}"]
                else
                  # stage is number
                  ["#{stage_or_code}.#{substage}"]
                end
      validate_stages
    end

    def validate_stages
      @stages.each do |stage|
        # raise an error when stage is wrong
        raise Errors::HarmonizedStageCodeInvalidError unless DESCRIPTIONS.key?(stage)
      end
    end

    def to_s
      if fuzzy?
        return "draft" if @stages.all? { |s| DRAFT_STAGES.include?(s) || CANCELED_STAGES.include?(s) }

        return "published" if @stages.all? { |s| PUBLISHED_STAGES.include?(s) }

        raise Errors::HarmonizedStageRenderingError, "cannot render fuzzy stages"
      else
        @stages.first
      end
    end

    def ==(other)
      (stages & other.stages) == other.stages
    end

    def fuzzy?
      @stages.length > 1
    end

    def stage
      raise Errors::HarmonizedStageRenderingError, "cannot render stage for fuzzy stages" if fuzzy?

      return nil if @stages.empty?

      @stages.first.split(".").first
    end

    def substage
      raise Errors::HarmonizedStageRenderingError, "cannot render substage for fuzzy stages" if fuzzy?

      @stages.first.split(".").last
    end

    def description
      DESCRIPTIONS[to_s]
    end
  end
end
