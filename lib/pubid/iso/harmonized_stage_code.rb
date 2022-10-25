module Pubid::Iso
  class HarmonizedStageCode
    include Comparable
    # attr_accessor :stage, :substage
    attr_accessor :stages

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
    }.freeze

    DRAFT_STAGES = %w[00.00 00.20 00.60 10.00 10.20 10.60 10.92 20.00 20.20 20.60 30.00
                      30.20 30.60 30.92 40.00 40.20 40.60 40.92 40.93 50.00 50.20 50.60
                      50.92].freeze

    CANCELED_STAGES = %w[00.98 10.98 20.98 30.98 40.98 50.98 95.99].freeze

    PUBLISHED_STAGES = %w[60.00 60.60 90.20 90.60 90.92 90.93 90.99 95.20 95.60 95.92].freeze

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

    # @param stage_or_code [String,Array<String>] stage number or whole harmonized code with substage
    #   or list or stages for fuzzy stages eg. "10", 10, "20.20", ["10.20", "20.20"]
    # @param substage [Integer, String] eg. "00", 0
    def initialize(stage_or_code, substage = "00")
      @stages = if stage_or_code.is_a?(Array)
                  stage_or_code
                elsif stage_or_code.is_a?(String) && DESCRIPTIONS.key?(stage_or_code)
                  [stage_or_code]
                # when stage is stage name
                elsif STAGES_NAMES.key?(stage_or_code)
                  ["#{STAGES_NAMES[stage_or_code]}.#{SUBSTAGES_NAMES[substage]}"]
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
        return "draft" if @stages.all? { |s| DRAFT_STAGES.include?(s) }

        return "canceled" if @stages.all? { |s| CANCELED_STAGES.include?(s) }

        return "published" if @stages.all? { |s| PUBLISHED_STAGES.include?(s) }

        raise Errors::HarmonizedStageRenderingError, "cannot render fuzzy stages"
      else
        @stages.first
      end
    end

    def ==(other)
      stages.intersection(other.stages) == other.stages
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
