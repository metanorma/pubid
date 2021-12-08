STAGES = YAML.load_file(File.join(File.dirname(__FILE__), "../../stages.yaml"))

module NistPubid
  class Stage
    attr_accessor :stage, :original_code

    def initialize(original_code)
      self.original_code = original_code
      @stage = self.class.regexp.match(original_code)&.[](1)
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

    def self.parse(code)
      new(regexp.match(code)&.to_s)
    end

    def self.regexp
      /\((#{STAGES.keys.join('|')})\)/
    end

    def nil?
      @stage.nil?
    end
  end
end
