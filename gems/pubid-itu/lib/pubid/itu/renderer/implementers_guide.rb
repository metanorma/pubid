module Pubid::Itu::Renderer
  class ImplementersGuide < Base
    def render_type_series(params)
      ("%{series}Imp" % params)
    end

    def render_number(number, _opts, params)
      number
    end
  end
end
