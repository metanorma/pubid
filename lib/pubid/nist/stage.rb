STAGES = YAML.load_file(File.join(File.dirname(__FILE__), "../../../stages.yaml"))

module Pubid::Nist
  class Stage
    attr_accessor :stage

    def initialize(stage)
      @stage = stage
    end

    def to_s(format = :short)
      return "" if nil?

      case format
      when :short
        "(#{@stage})"
      when :mr
        @stage
      else
        STAGES[@stage]
      end
    end

    def nil?
      @stage.nil?
    end
  end
end
