require_relative "base"

module Pubid::Cen::Renderer
  class HarmonizationDocument < Base
    def render_publisher(publisher, _opts, params)
      ""
    end

    def render_type(type, _opts, _params)
      "HD"
    end
  end
end
