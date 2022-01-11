SERIES = YAML.load_file(File.join(File.dirname(__FILE__), "../../series.yaml"))

module NistPubid
  class Serie
    attr_accessor :serie

    def initialize(serie:)
      @serie = serie == "NISTIR" ? "NIST IR" : serie
    end

    def to_s(format = :short)
      return @serie if format == :short

      result = SERIES[format.to_s][@serie]
      return @serie if result.nil? && format == :mr

      return SERIES["long"][@serie] if result.nil?

      result
    end

    def self.regexp
      /(#{(SERIES["long"].keys + SERIES["mr"].values
            .map { |v| v.gsub(".", '\.') } + ["NISTIR"])
            .sort_by(&:length).reverse.join('|')})/
    end
  end
end
