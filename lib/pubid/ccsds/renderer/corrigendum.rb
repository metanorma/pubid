module Pubid::Ccsds::Renderer
  class Corrigendum < Base
    def render_identifier(params)
      "%{base} Cor. %{number}" % params
    end
  end
end
