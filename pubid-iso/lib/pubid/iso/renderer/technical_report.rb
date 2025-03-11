require_relative "base"

module Pubid::Iso::Renderer
  class TechnicalReport < Base

    TYPE = "TR".freeze

    def omit_post_publisher_symbol?(_typed_stage, _stage, _opts)
      # always need post publisher symbol, because we always have to add "TR"
      false
    end
  end
end
