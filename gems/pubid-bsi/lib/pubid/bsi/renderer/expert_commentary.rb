require_relative "base"

module Pubid::Bsi::Renderer
  class ExpertCommentary < Base
    def render_identifier(params)
      "%{base} ExComm" % params
    end
  end
end
