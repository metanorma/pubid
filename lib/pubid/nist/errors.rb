module Pubid::Nist
  module Errors
    class ParseError < StandardError; end
    class SerieInvalidError < StandardError; end
    class PublisherInvalidError < StandardError; end
  end
end
