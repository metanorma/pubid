require_relative "base"

module Pubid::Iso::Renderer
  class Data < Base
    TYPE = "DATA".freeze

    def omit_post_publisher_symbol?(_typed_stage, _stage, _opts)
      false
    end
  end
end
