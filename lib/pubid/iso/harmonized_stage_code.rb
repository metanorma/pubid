module Pubid::Iso
  class HarmonizedStageCode
    attr_accessor :stage, :substage

    STAGES = { PWI: "00.00",
               NP: "10.00",
               AWI: "20.00",
               WD: "20.20",
               CD: "30.00",
               DIS: "40.00",
               FDIS: "50.00",
               PRF: "50.00",
               IS: "60.00" }.freeze

    DESCRIPTIONS = {
      "50.00" => "Final text received or FDIS registered for formal approval"
    }

    STAGES_NAMES = {
      approval: "50"
    }

    SUBSTAGES_NAMES = {
      registration: "00"
    }

    def initialize(stage_or_abbrev, substage)
      if STAGES.key?(stage_or_abbrev.to_sym)
        @stage, @substage = STAGES[stage_or_abbrev.to_sym].split(".")
      elsif STAGES_NAMES.key?(stage_or_abbrev)
        @stage = STAGES_NAMES[stage_or_abbrev]
        @substage = SUBSTAGES_NAMES[substage]
      else
        @stage, @substage = stage_or_abbrev, substage
      end
    end

    def to_s
      "#{stage}.#{substage}"
    end

    def abbrev
      STAGES.select { |k,v| v == to_s }.first&.first
    end

    def description
      DESCRIPTIONS[to_s]
    end
  end
end
