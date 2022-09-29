module Pubid::Iso
  module Errors
    class ParseError < StandardError; end
    class PublishedIterationError < StandardError; end
    class HarmonizedStageCodeInvalidError < StandardError; end
    class StageInvalidError < StandardError; end
    class IsStageIterationError < StandardError; end
    class IterationWithoutStageError < StandardError; end
    class WrongFormat < StandardError; end
    # Error raised when supplement applied to base document without publication year or stage
    class SupplementWithoutYearOrStageError < StandardError; end
    class NoEditionError < StandardError; end
  end
end
