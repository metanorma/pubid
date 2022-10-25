module Pubid::Iso
  class TypedStage
    attr_accessor :type, :stage, :typed_stage

    TYPED_STAGES = {
      dtr: {
        abbr: "DTR",
        type: :tr,
        name: "Draft Technical Report",
        harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 50.00 50.20 50.60 50.92],
      },
      dis: {
        abbr: "DIS",
        type: :is,
        name: "Draft International Standard",
        harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93],
      },
      dts: {
        abbr: "DTS",
        type: :ts,
        name: "Draft Technical Specification",
        harmonized_stages: %w[],
      },
      fdts: {
        abbr: "FDTS",
        type: :ts,
        name: "Final Draft Technical Specification",
        harmonized_stages: %w[],
      },
      fdtr: {
        abbr: "FDTR",
        type: :tr,
        name: "Final Draft Technical Report",
        harmonized_stages: %w[],
      },
      fdis: {
        abbr: "FDIS",
        type: :is,
        name: "Final Draft International Standard",
        harmonized_stages: %w[50.00],
      },
      dpas: {
        abbr: "DPAS",
        type: :pas,
        name: "Publicly Available Specification Draft",
        harmonized_stages: %w[],
      },
      damd: {
        abbr: { short: "DAM", long: "DAmd" },
        type: :amd,
        name: "Draft Amendment",
        harmonized_stages: %w[40.60],
      },
      dcor: {
        abbr: { short: "DCOR", long: "DCor" },
        type: :cor,
        name: "Draft Corrigendum",
        harmonized_stages: %w[40.60],
      }
    }.freeze

    # @param type [Symbol,Type] eg. :tr, Type.new(:tr)
    # @param stage [Symbol,Stage] eg. :CD, Stage.new(abbr: :CD)
    def initialize(abbr: nil, type: nil, stage: nil)
      @type = type.is_a?(Type) ? type : Type.new(type) if type
      @stage = stage.is_a?(Stage) ? stage : Stage.new(abbr: stage) if stage

      if abbr
        raise Errors::TypeStageInvalidError, "#{abbr} is not valid typed stage" unless TYPED_STAGES.key?(abbr)
        assign_abbreviation(abbr)
        #@stage = Stage.new(harmonized_code: TYPED_STAGES[abbr][:harmonized_stages].first.to_s + ".00")
      elsif !@stage.nil?
        # lookup for typed stage
        @typed_stage = lookup_typed_stage
      end
    end

    def lookup_typed_stage
      TYPED_STAGES.each do |typed_stage, values|
        if values[:harmonized_stages].include?(@stage.harmonized_code.to_s) && values[:type] == @type&.type
          return typed_stage
        end
      end
      nil
    end

    # Assigns type and stage according to provided typed stage abbreviation
    # @param abbr [Symbol] eg. :dtr, :damd, :dis
    def assign_abbreviation(abbr)
      @typed_stage = abbr
      @type = Type.new(TYPED_STAGES[abbr][:type])
      @stage = Stage.new(harmonized_code: HarmonizedStageCode.new(TYPED_STAGES[abbr][:harmonized_stages]))
    end

    # Render typed stage
    # @param stage_format_long [Boolean] render stage in long or short format
    def to_s(stage_format_long = true)
      # return "" if @type == :amd || @type == :cor
      if @typed_stage
        if TYPED_STAGES[@typed_stage][:abbr].is_a?(Hash)
          return TYPED_STAGES[@typed_stage][:abbr][stage_format_long ? :long : :short]
        else
          return TYPED_STAGES[@typed_stage][:abbr]
        end
      end

      result = (@stage && @stage.abbr != "IS") ? "#{@stage.abbr}" : ""
      result += " " if !result.empty? && @type && stage_format_long
      result + if stage_format_long
                 "#{@type&.to_s}"
               else
                 if @type == :amd
                   "AM"
                 elsif @type == :cor
                   "COR"
                 else
                   "#{@type&.to_s}"
                 end
               end
    end

    # Check if typed stage listed in TYPED_STAGES constant
    # @param typed_stage [String,Symbol] typed stage abbreviation, eg. "DTS", :dts, "DAmd", :damd
    def self.has_typed_stage?(typed_stage)
      return true if TYPED_STAGES.key?(typed_stage)

      TYPED_STAGES.any? do |_, v|
        if v[:abbr].is_a?(Hash)
          v[:abbr].values.include?(typed_stage)
        else
          v[:abbr] == typed_stage
        end
      end
    end

    # Assigns stage or typed stage depending on provided string
    # @param stage_or_typed_stage [String, Stage] eg. "DTR", "CD", Stage.new(:CD)
    def parse_stage(stage_or_typed_stage)
      return assign_abbreviation(stage_or_typed_stage.downcase.to_sym) if self.class.has_typed_stage?(stage_or_typed_stage)

      if stage_or_typed_stage.is_a?(Stage)
        @stage = stage_or_typed_stage
      elsif Stage.has_stage?(stage_or_typed_stage)
        @stage = Stage.parse(stage_or_typed_stage)
      else
        raise Errors::TypeStageParseError, "cannot parse typed stage or stage"
      end
      @typed_stage = lookup_typed_stage
    end

    # Parse stage or typed stage
    # @return [TypedStage] typed stage object with parsed stage and typed stage
    def self.parse(stage_or_typed_stage)
      return stage_or_typed_stage if stage_or_typed_stage.is_a?(TypedStage)

      typed_stage = new
      typed_stage.parse_stage(stage_or_typed_stage)
      typed_stage
      # return stage_or_typed_stage if stage_or_typed_stage.is_a?(TypedStage)
      #
      # return new(abbr: stage_or_typed_stage.downcase.to_sym) if has_typed_stage?(stage_or_typed_stage.to_s)
      #
      # return new(stage: stage_or_typed_stage) if stage_or_typed_stage.is_a?(Stage)
      #
      # return new(stage: Stage.parse(stage_or_typed_stage)) if Stage.has_stage?(stage_or_typed_stage)
      #
      # raise Errors::TypeStageParseError, "cannot parse typed stage or stage"
    end
  end
end
