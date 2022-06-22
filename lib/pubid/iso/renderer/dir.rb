module Pubid::Iso::Renderer
  class Dir < Pubid::Core::Renderer::Base

    def render_identifier(params)
      "%{publisher}%{copublisher} DIR%{dirtype}%{number}%{year}%{supplement}" % params
    end

    def render_number(number, _opts, _params)
      " #{number}"
    end

    def render_dirtype(dirtype, _opts, _params)
      " #{dirtype}"
    end

    def render_supplement(supplement, _opts, _params)
      if supplement.publisher
        " #{supplement.publisher} SUP"
      else
        " SUP"
      end + (supplement.number && ":#{supplement.number}" || "")
    end
  end
end
