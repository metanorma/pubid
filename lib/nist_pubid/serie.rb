SERIES = YAML.load_file(File.join(File.dirname(__FILE__), "../../series.yaml"))

module NistPubid
  class Serie
    attr_accessor :serie

    def initialize(serie:)
      @serie = serie
    end

    def to_s(format)
      return @serie if %i[short mr].include?(format)

      result = SERIES[format.to_s][@serie]
      return SERIES["long"][@serie] if result.nil?

      result
    end

    def self.series_keys
      SERIES["long"].keys + SERIES["mr"].values
    end
  end
end
