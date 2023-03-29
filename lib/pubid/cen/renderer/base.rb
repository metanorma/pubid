module Pubid::Cen::Renderer
  class Base < Pubid::Core::Renderer::Base
    def render_identifier(params)
      "%{stage}%{publisher}%{type} %{number}%{part}%{year}" % params
    end

    def render_part(part, opts, _params)
      return "-#{part.reverse.join('-')}" if part.is_a?(Array)

      "-#{part}"
    end
  end
end
