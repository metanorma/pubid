require_relative "base"

module Pubid::Bsi::Renderer
  class PubliclyAvailableSpecification < Base

    TYPE = "PAS".freeze

    def render_publisher(_publisher, _, _)
      TYPE
    end
  end
end
