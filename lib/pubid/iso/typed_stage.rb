module Pubid::Iso
  class TypedStage
    attr_accessor :type, :stage, :typed_stage

    TYPED_STAGES = {
    }.freeze

    # @param type [Symbol,Type] eg. :tr, Type.new(:tr)
    # @param stage [Symbol,Stage] eg. :CD, Stage.new(abbr: :CD)
    def initialize(abbr: nil, type: nil, stage: nil)
      @type = if type
                type.is_a?(Type) ? type : Type.new(type)
              else
                Type.new
              end
      @stage = stage.is_a?(Stage) ? stage : Stage.new(abbr: stage) if stage

      if abbr
        raise Errors::TypeStageInvalidError, "#{abbr} is not valid typed stage" unless TYPED_STAGES.key?(abbr)
        assign_abbreviation(abbr)
      elsif !@stage.nil? && !@stage.abbr
        # lookup for typed stage
        @typed_stage = lookup_typed_stage
      end
    end

    def lookup_typed_stage
      return nil unless @stage

      TYPED_STAGES.each do |typed_stage, values|
        if values[:harmonized_stages].include?(@stage.harmonized_code.to_s) &&
          values[:type] == @type&.type
          return typed_stage
        end
      end
      nil
    end

    # Assigns type and stage according to provided typed stage abbreviation
    # @param abbr [Symbol] eg. :dtr, :damd, :dis
    def assign_abbreviation(abbr)
      @typed_stage = if TYPED_STAGES.key?(abbr.downcase.to_sym)
                       abbr.downcase.to_sym
                     else
                       TYPED_STAGES.select do |_, v|
                         if v[:abbr].is_a?(Hash)
                           v[:abbr].values.include?(abbr)
                         else
                           v[:abbr] == abbr
                         end
                       end.keys.first
                     end

      @type = Type.new(TYPED_STAGES[@typed_stage][:type])
      @stage = Stage.new(harmonized_code: HarmonizedStageCode.new(TYPED_STAGES[@typed_stage][:harmonized_stages]))
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

      result = @stage ? @stage.abbr.to_s : ""

      return result unless @type

      # do not render IS type
      return result if @type == :is

      result += " " if !result.empty? && @type && stage_format_long
      return (result + @type&.to_s) if stage_format_long

      return result + "AM" if @type == :amd
      return result + "COR" if @type == :cor

      result + @type&.to_s
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

    # Assigns stage or type or typed stage or stage and type depending on provided string
    # @param stage_or_typed_stage [String, Stage] eg. "DTR", "CD", Stage.new(:CD), "TR", "CD Amd", :dtr
    def parse_stage(stage_or_typed_stage)
      if self.class.has_typed_stage?(stage_or_typed_stage)
        return assign_abbreviation(stage_or_typed_stage)
      end

      if stage_or_typed_stage.is_a?(Stage)
        @stage = stage_or_typed_stage
      elsif stage_or_typed_stage.is_a?(String) && stage_or_typed_stage.split.count == 2 &&
          Stage.has_stage?(stage_or_typed_stage.split.first)
        # stage and type ("CD Amd")
        @stage = Stage.parse(stage_or_typed_stage.split.first)
        @type = Type.parse(stage_or_typed_stage.split.last)
      elsif Type.has_type?(stage_or_typed_stage)
        @type = Type.parse(stage_or_typed_stage)
      elsif Stage.has_stage?(stage_or_typed_stage)
        @stage = Stage.parse(stage_or_typed_stage.to_s)
      else
        raise Errors::TypeStageParseError, "cannot parse typed stage or stage"
      end
      @typed_stage = lookup_typed_stage unless @stage&.abbr
    end

    # Parse stage or typed stage
    # @return [TypedStage] typed stage object with parsed stage and typed stage
    def self.parse(stage_or_typed_stage)
      return stage_or_typed_stage if stage_or_typed_stage.is_a?(TypedStage)

      typed_stage = new
      typed_stage.parse_stage(stage_or_typed_stage)
      typed_stage
    end

    def name
      TYPED_STAGES[@typed_stage][:name]
    end

    def ==(other)
      return false if other.nil?

      type == other.type && typed_stage == other.typed_stage && stage == other.stage
    end
  end
end
