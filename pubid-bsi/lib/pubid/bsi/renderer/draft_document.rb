require_relative "base"

module Pubid::Bsi::Renderer
  class DraftDocument < Base

    TYPE = "DD".freeze

    def render_publisher(_publisher, _, _)
      TYPE
    end
  end
end
