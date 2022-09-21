module Pubid::Iso
  module Errors
    class ParseError < StandardError; end
    class PublishedIterationError < StandardError; end
    class HarmonizedStageCodeInvalidError < StandardError; end
    class StageInvalidError < StandardError; end
    class IsStageIterationError < StandardError; end
    class WrongFormat < StandardError; end
    class SupplementWithoutYearError < StandardError; end
    class NoEditionError < StandardError; end
  end
end
