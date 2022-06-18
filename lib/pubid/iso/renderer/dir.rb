module Pubid::Iso::Renderer
  class Dir < Pubid::Core::Renderer::Base

    def render_identifier(params)
      "%{publisher}%{copublisher} DIR%{dirtype} %{number}%{supplement}" % params
    end

    def render_dirtype(dirtype, _opts, _params)
      " #{dirtype}"
    end

    def render_supplement(supplement, _opts, _params)
      " SUP:#{supplement.number}"
    end
  end
end
