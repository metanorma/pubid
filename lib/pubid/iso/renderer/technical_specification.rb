require_relative "base"

module Pubid::Iso::Renderer
  class TechnicalSpecification < Base

    TYPE = "TS".freeze

    def omit_post_publisher_symbol?(_typed_stage, _stage, _opts)
      # always need post publisher symbol, because we always have to add "TR"
      false
    end
  end
end
