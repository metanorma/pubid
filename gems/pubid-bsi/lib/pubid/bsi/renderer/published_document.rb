require_relative "base"

module Pubid::Bsi::Renderer
  class PublishedDocument < Base

    TYPE = "PD".freeze

    def render_publisher(_publisher, _, _)
      TYPE
    end
  end
end
