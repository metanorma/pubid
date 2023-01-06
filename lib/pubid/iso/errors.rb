module Pubid::Iso
  module Errors
    class ParseError < StandardError; end
    class PublishedIterationError < StandardError; end
    class IsStageIterationError < StandardError; end
    class IterationWithoutStageError < StandardError; end
    class WrongFormat < StandardError; end
    # Error raised when supplement applied to base document without publication year or stage
    class SupplementWithoutYearOrStageError < StandardError; end
    class NoEditionError < StandardError; end
    class WrongTypeError < StandardError; end
    class ParseTypeError < StandardError; end
    class TypeStageInvalidError < StandardError; end
    class TypeStageParseError < StandardError; end

    class SupplementRenderingError < StandardError; end
  end
end
