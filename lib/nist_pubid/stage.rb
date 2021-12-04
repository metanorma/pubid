STAGES = YAML.load_file(File.join(File.dirname(__FILE__), "../../stages.yaml"))

module NistPubid
  class Stage
    attr_accessor :stage

    def initialize(stage:)
      @stage = stage
    end

    def to_s(format)
      return "" if @stage.nil?
      return "#{@stage} " if %i[short mr].include?(format)

      "#{STAGES[@stage]} "
    end

    def self.stages_keys
      STAGES.keys
    end
  end
end
