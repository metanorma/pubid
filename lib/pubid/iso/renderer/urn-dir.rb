module Pubid::Iso::Renderer
  class UrnDir < Pubid::Core::Renderer::Urn

    def render_identifier(params)
      "urn:iso:doc:%{publisher}%{copublisher}:dir%{dirtype}%{number}%{supplement}" % params
    end

    def render_number(number, _opts, _params)
      ":#{number}"
    end

    def render_dirtype(dirtype, _opts, _params)
      ":#{dirtype.downcase}"
    end

    def render_supplement(supplement, _opts, _params)
      if supplement.publisher
        ":sup:#{supplement.publisher.downcase}"
      else
        ":sup"
      end + (supplement.number && ":#{supplement.number}" || "")
    end
  end
end
