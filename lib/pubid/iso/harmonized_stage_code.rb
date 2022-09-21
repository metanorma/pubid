module Pubid::Iso
  class HarmonizedStageCode
    include Comparable
    attr_accessor :stage, :substage

    DESCRIPTIONS = {
      "00.00" => "Proposal for new project received",
      "00.20" => "Proposal for new project under review",
      "00.60" => "Close of review",
      "00.98" => "Proposal for new project abandoned",
      "00.99" => "Approval to ballot proposal for new project",
      "10.00" => "Proposal for new project registered",
      "10.20" => "New project ballot initiated",
      "10.60" => "Close of voting",
      "10.92" => "Proposal returned to submitter for further definition",
      "10.98" => "New project rejected",
      "10.99" => "New project approved",
      "20.00" => "New project registered in TC/SC work programme",
      "20.20" => "Working draft (WD) study initiated",
      "20.60" => "Close of comment period",
      "20.98" => "Project deleted",
      "20.99" => "WD approved for registration as CD",
      "30.00" => "Committee draft (CD) registered",
      "30.20" => "CD study/ballot initiated",
      "30.60" => "Close of voting/ comment period",
      "30.92" => "CD referred back to Working Group",
      "30.98" => "Project deleted",
      "30.99" => "CD approved for registration as DIS",
      "40.00" => "DIS registered",
      "40.20" => "DIS ballot initiated: 12 weeks",
      "40.60" => "Close of voting",
      "40.92" => "Full report circulated: DIS referred back to TC or SC",
      "40.93" => "Full report circulated: decision for new DIS ballot",
      "40.98" => "Project deleted",
      "40.99" => "Full report circulated: DIS approved for registration as FDIS",
      "50.00" => "Final text received or FDIS registered for formal approval",
      "50.20" => "Proof sent to secretariat or FDIS ballot initiated: 8 weeks",
      "50.60" => "Close of voting. Proof returned by secretariat",
      "50.92" => "FDIS or proof referred back to TC or SC",
      "50.98" => "Project deleted",
      "50.99" => "FDIS or proof approved for publication",
      "60.00" => "International Standard under publication",
      "60.60" => "International Standard published",
      "90.20" => "International Standard under systematic review",
      "90.60" => "Close of review",
      "90.92" => "International Standard to be revised",
      "90.93" => "International Standard confirmed",
      "90.99" => "Withdrawal of International Standard proposed by TC or SC",
      "95.20" => "Withdrawal ballot initiated",
      "95.60" => "Close of voting",
      "95.92" => "Decision not to withdraw International Standard",
      "95.99" => "Withdrawal of International Standard"
    }

    STAGES_NAMES = {
      preliminary: "00",
      proposal: "10",
      preparatory: "20",
      committee: "30",
      enquiry: "40",
      approval: "50",
      publication: "60",
      review: "90",
      withdrawal: "95",
    }.freeze

    SUBSTAGES_NAMES = {
      registration: "00",
      start_of_main_action: "20",
      completion_of_main_action: "60",
      repeat_an_earlier_phase: "92",
      repeat_current_phase: "93",
      abandon: "98",
      proceed: "99",
    }.freeze

    def initialize(stage, substage = "00")
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
      raise Errors::HarmonizedStageCodeInvalidError if Integer(stage).nil?

      # raise an error when substage wrong
      raise Errors::HarmonizedStageCodeInvalidError unless DESCRIPTIONS.key?(to_s)
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
