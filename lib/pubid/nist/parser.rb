module Pubid::Nist
  class Parser < Pubid::Core::Parser
    attr_accessor :parsed

    rule(:series) do
      (array_to_str(SERIES["long"].keys.sort_by(&:length).reverse.flatten).as(:series) |
        array_to_str(SERIES["mr"].values).as(:series_mr) |
        (str("NIST ") >> array_to_str(SERIES["long"].keys.sort_by(&:length).reverse.flatten).as(:series))) >>
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
      parser = find_parser(series)
      begin
        parsed = parser.new.parse(parsed[:remaining].to_s)
      rescue Parslet::ParseFailed
        # for PubID 1.0 identifier series specific parser might fail,
        # so parse using Default parser which is comply with PubID 1.0
        parsed = Parsers::Default.new.parse(parsed[:remaining].to_s)
      end
      parsed.is_a?(Array) ? parsed << { series: series } : parsed.merge({ series: series })
    end

    def find_parser(series)
      PARSERS_CLASSES[series] || Pubid::Nist::Parsers::Default
    end
  end
end
