module NistPubid
  class Serie
    attr_accessor :serie

    def initialize(serie:)
      @serie = serie
    end

    def to_s(format)
      return @serie if format == :short || format == :mr

      self.class.series[format.to_s][@serie]
    end

    def self.series
      @series ||= YAML.load_file(File.join(File.dirname(__FILE__), "../../series.yaml"))
    end

    def self.series_keys
      series["long"].keys + series["mr"].values
    end
  end
end
