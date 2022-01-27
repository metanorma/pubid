SERIES = YAML.load_file(File.join(File.dirname(__FILE__), "../../series.yaml"))

module NistPubid
  class Serie
    attr_accessor :serie, :parsed

    SERIE_REGEXP = nil
    EDITION_REGEXP = /(?<=\.)?(?<!Upd\d)(?:\d+-\d+)?
                     (?<!add|sup)(?<prepend>e-?|Ed\.\s|Edition\s)
                     (?:(?<year>\d{4})|(?<sequence>\d+[A-Z]?)(?!-))/x.freeze

    DOCNUMBER_REGEXP = nil
    SUPPLEMENT_REGEXP = /(?:(?:supp?)-?(\d*)|Supplement|Suppl.)/.freeze
    PART_REGEXP = /(?<=\.)?(?<![a-z])+(?:pt|Pt|p)(?(1)-)([A-Z\d]+)/.freeze

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

      # if self::SERIE_REGEXP && self::SERIE_REGEXP.match?(code)
      #   new(serie: self.name.split("::").last.gsub!(/(.)([A-Z])/,'\1 \2').upcase,
      #       parsed: self::SERIE_REGEXP.match(code).to_s)
      # end

      ObjectSpace.each_object(NistPubid::Serie.singleton_class) do |klass|
        if klass::SERIE_REGEXP&.match?(code)
          return klass.new(
            serie: klass.name.split("::").last.gsub!(/(.)([A-Z])/, '\1 \2').upcase,
            parsed: klass::SERIE_REGEXP.match(code).captures.join,
          )
        end
        # return klass.parse(code) if klass.methods.include?(:match?) && klass.match?(code)
      end

      serie = /#{SERIES["long"].keys.sort_by(&:length).reverse.join('|')}/.match(code)
      return get_class(serie.to_s, serie.to_s) if serie

      serie = /#{filter_by_publisher(publisher, SERIES["long"]).values.join('|')}/.match(code)
      return get_class(filter_by_publisher(publisher, SERIES["long"]).key(serie.to_s), serie.to_s) if serie

      serie = /#{filter_by_publisher(publisher, SERIES["abbrev"]).values.join('|')}/.match(code)
      return get_class(filter_by_publisher(publisher, SERIES["abbrev"]).key(serie.to_s), serie.to_s) if serie

      serie = /#{SERIES["mr"].values.join('|')}/.match(code)
      return get_class(SERIES["mr"].key(serie.to_s), serie.to_s) if serie

      nil
    end

    def parse_edition(code)
      edition = self.class::EDITION_REGEXP.match(code)

      if !edition && !self.instance_of?(NistPubid::Serie)
        edition = NistPubid::Serie::EDITION_REGEXP.match(code)
      end

      parsed = edition&.captures&.join&.to_s

      return nil if edition.nil? || edition.captures.compact.empty?

      if edition.named_captures.key?("date_with_month") && edition[:date_with_month]
        date = Date.parse("01/" + edition[:date_with_month])
        { month: date.month, year: date.year, parsed: parsed }
      elsif edition.named_captures.key?("date_with_day") && edition[:date_with_day]
        date = Date.parse(edition[:date_with_day])
        { day: date.day, month: date.month, year: date.year, parsed: parsed }
      elsif edition.named_captures.key?("year") && edition[:year]
        { year: edition[:year].to_i, parsed: parsed }
      else
        { sequence: edition[:sequence], parsed: parsed }
      end
    end

    def parse_docnumber(code, code_original)
      localities = "[Pp]t\\d+|r(?:\\d+|[A-Za-z]?)|e\\d+|p|v|sec\\d+|inde?x|err(?:ata)?|ins(?:ert)|app|ins?"
      excluded_parts = "(?!#{localities}|supp?)"

      if self.class::DOCNUMBER_REGEXP
        docnumber = self.class::DOCNUMBER_REGEXP.match(code_original)&.captures&.join

        return docnumber if docnumber || self.instance_of?(NistPubid::Serie)
      end

      docnumber ||=
        /(?:#{parsed.gsub(" ", "(?:\s|\.)")})(?:\s|\.)?([0-9]+)(?:#{localities})(-[0-9]+)?/
          .match(code)&.captures&.join

      docnumber ||=
        /(?:#{parsed.gsub(" ", "(?:\s|\.)")})(?:\s|\.)? # match serie
          ([0-9]+ # first part of report number
            (?:#{excluded_parts}[A-Za-z]+)? # with letter but without localities
            (?:-m)? # for NBS CRPL 4-m-5
            (?:-[A-Za]+)? # for NIST SP 1075-NCNR, NIST SP 1113-BFRL, NIST IR 6529-a
            (?:-[0-9.]+)? # second part
            (?:
              (?: # only big letter
                (#{excluded_parts}[A-Z]|(?![a-z]))+|#{excluded_parts}[a-z]?|#{excluded_parts}[a-z]+
              )? # or small letter but without localities
            )
          )/x.match(code)&.[](1)&.upcase

      unless docnumber
        raise Errors::ParseError.new(
          "failed to parse document identifier for #{code}",
        )
      end

      docnumber
    end

    def parse_supplement(code)
      supplement = self.class::SUPPLEMENT_REGEXP.match(code)
      return nil unless supplement

      supplement[1].nil? ? "" : supplement[1]
    end

    def parse_part(code)
      self.class::PART_REGEXP.match(code)&.captures&.join
    end

    def self.regexp
      /(#{(SERIES["long"].keys + SERIES["mr"].values + SERIES["long"].values
            .map { |v| v.gsub(".", '\.') } + ["NISTIR"])
            .sort_by(&:length).reverse.join('|')})/
    end
  end
end
