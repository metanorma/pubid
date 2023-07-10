module Pubid::Itu::Renderer
  class ImplementersGuide < Base
    def render_type_series(params)
      "%{series}%{type}" % params
    end

    def render_number(number, _opts, params)
      number
    end

    def render_type(type, opts, _params)
      params[:series] ? ".Imp" : "Imp"
    end
  end
end
