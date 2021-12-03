module NistPubid
  class Serie
    attr_accessor :serie

    def initialize(serie:)
      @serie = serie
    end

    def to_s(format)
      return @serie if format == :short || format == :mr

      result = self.class.series[format.to_s][@serie]
      return self.class.series["long"][@serie] if result.nil?

      result
    end

    def self.series
      @series ||= YAML.load_file(File.join(File.dirname(__FILE__), "../../series.yaml"))
    end

    def self.series_keys
      series["long"].keys + series["mr"].values
    end
  end
end
