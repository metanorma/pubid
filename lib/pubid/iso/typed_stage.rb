module Pubid::Iso
  class TypedStage
    attr_accessor :type, :stage, :typed_stage

    TYPED_STAGES = {
      dtr: {
        abbr: "DTR",
        type: :tr,
        name: "Draft Technical Report",
        harmonized_stages: [ 40, 50 ]
      },
    }.freeze

    # @param type [Symbol,Type] eg. :tr, Type.new(:tr)
    # @param stage [Symbol,Stage] eg. :CD, Stage.new(abbr: :CD)
    def initialize(abbr: nil, type: nil, stage: nil)
      @type = type.is_a?(Type) ? type : Type.new(type) if type
      @stage = stage.is_a?(Stage) ? stage : Stage.new(abbr: stage) if stage

      if abbr
        raise Errors::TypeStageInvalidError, "#{abbr} is not valid type stage" unless TYPED_STAGES.key?(abbr)

        @typed_stage = abbr
        @type = Type.new(TYPED_STAGES[abbr][:type])
        @stage = Stage.new(harmonized_code: TYPED_STAGES[abbr][:harmonized_stages].first.to_s + ".00")
      else
        # lookup for type_stage
        TYPED_STAGES.each do |typed_stage, values|
          if stage && values[:harmonized_stages].map { |v| "#{v}.00" }
                                              .include?(@stage.harmonized_code.to_s) && values[:type] == type
            @typed_stage = typed_stage
          end
        end
      end
    end

    def to_s
      return TYPED_STAGES[@typed_stage][:abbr] if @typed_stage

      "#{@stage.abbr} #{@type.to_s}"
    end
  end
end
