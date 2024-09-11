module Pubid::Itu::Renderer
  class Contribution < Base
    def render_identifier(params)
      ("%{series}-C%{number}" % params)
    end

    def render_number(number, _opts, params)
      number
    end
  end
end
