module Pubid::Iso
  module Errors
    class ParseError < StandardError; end
    class PublishedIterationError < StandardError; end
    class HarmonizedStageCodeInvalidError < StandardError; end
    class CodeInvalidError < StandardError; end
    class IsStageIterationError < StandardError; end
    class WrongFormat < StandardError; end
    class SupplementWithoutYearError < StandardError; end
  end
end
