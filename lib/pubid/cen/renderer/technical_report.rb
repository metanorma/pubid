require_relative "base"

module Pubid::Cen::Renderer
  class TechnicalReport < Base
    def render_type(type, _opts, _params)
      "/TR"
    end
  end
end
