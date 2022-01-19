SERIES = YAML.load_file(File.join(File.dirname(__FILE__), "../../series.yaml"))

module NistPubid
  class Serie
    attr_accessor :serie, :parsed

    EDITION_REGEXP = /(?<=\.)?(?<!Upd\d)(?:\d+-\d+)?
                     (?<!add|sup)(?<prepend>e-?|Ed\.\s|Edition\s)
                     (?:(?<year>\d{4})|(?<sequence>\d+[A-Z]?)(?!-))/x.freeze

    DOCNUMBER_REGEXP = nil

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

    def self.filter_by_publisher(publisher, series)
      if publisher.to_s == "NIST"
        series.select { |k,v| k =~ /^(?!NBS)/ }
      else
        series.select { |k,v| k =~ /^(?!NIST)/ }
      end
    end

    def self.get_class(series, parsed)
      if SERIES_CLASSES.has_key?(series)
        SERIES_CLASSES[series].new(serie: series, parsed: parsed)
      else
        new(serie: series, parsed: parsed)
      end
    end

    def self.parse(code, publisher = nil)
      publisher = Publisher.parse(code) if publisher.nil?

      serie = /#{SERIES["long"].keys.sort_by(&:length).reverse.join('|')}/.match(code)
      return get_class(serie.to_s,serie.to_s) if serie

      serie = /#{filter_by_publisher(publisher, SERIES["long"]).values.join('|')}/.match(code)
      return get_class(filter_by_publisher(publisher, SERIES["long"]).key(serie.to_s), serie.to_s) if serie

      serie = /#{filter_by_publisher(publisher, SERIES["abbrev"]).values.join('|')}/.match(code)
      return get_class(filter_by_publisher(publisher, SERIES["abbrev"]).key(serie.to_s), serie.to_s) if serie

      serie = /#{SERIES["mr"].values.join('|')}/.match(code)
      return get_class(SERIES["mr"].key(serie.to_s), serie.to_s) if serie
    end

    def self.regexp
      /(#{(SERIES["long"].keys + SERIES["mr"].values + SERIES["long"].values
            .map { |v| v.gsub(".", '\.') } + ["NISTIR"])
            .sort_by(&:length).reverse.join('|')})/
    end
  end
end
