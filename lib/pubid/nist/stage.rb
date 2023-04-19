STAGES = YAML.load_file(File.join(File.dirname(__FILE__), "../../../stages.yaml"))

module Pubid::Nist
  class Stage
    attr_accessor :id, :type

    def initialize(id:, type:)
      @id, @type = id.to_s.downcase, type.to_s.downcase
    end

    def to_s(format = :short)
      return "" if nil?

      case format
      when :short
        " #{@id}#{@type}"
      when :mr
        "#{@id}#{@type}"
      else
        "#{STAGES['id'][@id]} #{STAGES['type'][@type]}"
      end
    end

    def nil?
      @id.nil? && @type.nil?
    end
  end
end
