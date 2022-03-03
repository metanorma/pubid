SERIES = YAML.load_file(File.join(File.dirname(__FILE__), "../../../series.yaml"))

module Pubid::Nist
  class Serie
    attr_accessor :serie, :parsed

    def initialize(serie:, parsed: nil)
      @serie = serie
      @parsed = parsed
    end

    def to_s(format = :short)
      return @serie if format == :short

      result = SERIES[format.to_s][@serie]
      return @serie if result.nil? && format == :mr

      return SERIES["long"][@serie] if result.nil?

      result
    end

    def ==(other)
      other.serie == @serie
    end
  end
end
