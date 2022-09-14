module Pubid::Iso
  module Errors
    class ParseError < StandardError; end
    class PublishedIterationError < StandardError; end
    class HarmonizedStageCodeInvalidError < StandardError; end
    class CodeInvalidError < StandardError; end
    class WrongFormat < StandardError; end
  end
end
