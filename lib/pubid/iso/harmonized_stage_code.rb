module Pubid::Iso
  class HarmonizedStageCode
    include Comparable
    attr_accessor :stage, :substage

    DESCRIPTIONS = {
      "50.00" => "Final text received or FDIS registered for formal approval"
    }

    STAGES_NAMES = {
      approval: "50"
    }

    SUBSTAGES_NAMES = {
      registration: "00"
    }

    def initialize(stage, substage = nil)
      # when stage is stage name
      if STAGES_NAMES.key?(stage)
        @stage = STAGES_NAMES[stage]
        @substage = SUBSTAGES_NAMES[substage]
      else
        # stage is number
        validate_stage(stage, substage)
        @stage, @substage = stage, substage
      end
    end

    def validate_stage(stage, substage)
      # raise an error if stage is not number
      raise Errors::HarmonizedStageCodeNotValidError if Integer(stage).nil?

      # raise an error when substage wrong
      raise Errors::HarmonizedStageCodeNotValidError if stage == "90" && substage == "00"
      # raise Errors::HarmonizedStageCodeNotValidError if stage.to_i
    end

    def to_s
      "#{stage}.#{substage}"
    end

    def ==(other)
      stage == other.stage && substage == other.substage
    end

    def description
      DESCRIPTIONS[to_s]
    end
  end
end
