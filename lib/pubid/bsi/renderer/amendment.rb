require_relative "base"

module Pubid::Bsi::Renderer
  class Amendment < Pubid::Core::Renderer::Base
    def render_identifier(params)
      "+A%{number}%{year}" % params
    end
  end
end
