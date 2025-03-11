require_relative "base"

module Pubid::Cen::Renderer
  class Guide < Base
    def render_type(type, _opts, _params)
      " Guide"
    end
  end
end
