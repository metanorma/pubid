module Pubid::Core
  module Errors
    class ParseError < StandardError; end
    class HarmonizedStageCodeInvalidError < StandardError; end
    class StageInvalidError < StandardError; end
    class HarmonizedStageRenderingError < StandardError; end
  end
end
