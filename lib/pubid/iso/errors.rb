module Pubid::Iso
  module Errors
    class ParseError < StandardError; end
    class PublishedIterationError < StandardError; end
    class HarmonizedStageCodeNotValidError < StandardError; end
    class CodeNotValidError < StandardError; end
  end
end
