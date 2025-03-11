module Pubid::Itu::Renderer
  class Contribution < Base
    def render_identifier(params, _opts)
      ("%{series}-C%{number}" % params)
    end

    def render_series(series, _opts, _params)
      series
    end

    def render_number(number, _opts, params)
      number
    end
  end
end
