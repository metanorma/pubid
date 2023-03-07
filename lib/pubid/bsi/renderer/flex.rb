require_relative "base"

module Pubid::Bsi::Renderer
  class Flex < Base

    TYPE = "Flex".freeze

    def render_publisher(_publisher, _, _)
      "BSI #{TYPE}"
    end
  end
end
