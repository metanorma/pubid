module Pubid::Nist
  class Parser < Pubid::Core::Parser
    attr_accessor :parsed

    rule(:series) do
      (array_to_str(SERIES["long"].keys.sort_by(&:length).reverse.flatten).as(:series) |
        array_to_str(SERIES["mr"].values).as(:series_mr) |
        ((str("NBS") | str("NIST")).as(:publisher) >> (space | dot) >> array_to_str(SERIES["long"].keys.sort_by(&:length).reverse.flatten).as(:series))) >>
        any.repeat.as(:remaining)
    end

    root(:series)

    def parse(code)
      parsed = super(code)
      series = if parsed[:series]
                 parsed[:series].to_s
               else
                 SERIES["mr"].key(parsed[:series_mr].to_s)
               end
      publisher = parsed[:publisher]
      parser = find_parser(publisher, series)
      begin
        parsed = parser.new.parse(parsed[:remaining].to_s)
      rescue Parslet::ParseFailed
        # for PubID 1.0 identifier series specific parser might fail,
        # so parse using Default parser which is comply with PubID 1.0
        parsed = Parsers::Default.new.parse(parsed[:remaining].to_s)
      end
      if publisher
        parsed.is_a?(Array) ? parsed << { series: series, publisher: publisher } : parsed.merge({ series: series, publisher: publisher })
      else
        parsed.is_a?(Array) ? parsed << { series: series } : parsed.merge({ series: series })
      end
    end

    def find_parser(publisher, series)
      PARSERS_CLASSES[series] || PARSERS_CLASSES["#{publisher} #{series}"] || Pubid::Nist::Parsers::Default
    end
  end
end
