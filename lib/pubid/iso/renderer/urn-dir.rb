module Pubid::Iso::Renderer
  class UrnDir < Pubid::Core::Renderer::Urn

    def render_identifier(params)
      "urn:iso:doc:%{publisher}%{copublisher}:dir%{dirtype}:%{number}%{supplement}" % params
    end

    def render_dirtype(dirtype, _opts, _params)
      ":#{dirtype.downcase}"
    end

    def render_supplement(supplement, _opts, _params)
      ":sup:#{supplement.number}"
    end
  end
end
