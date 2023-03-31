module Pubid::Cen::Renderer
  class Base < Pubid::Core::Renderer::Base
    def render_identifier(params)
      "%{stage}%{publisher}%{type} %{number}%{part}%{year}%{supplements}" % params
    end

    def render_part(part, opts, _params)
      return "-#{part.reverse.join('-')}" if part.is_a?(Array)

      "-#{part}"
    end

    def sort_supplements(supplements)
      supplements.sort_by { |a| (a.year * 100) + a.number.to_i }
    end

    def render_supplements(supplements, _opts, _params)
      sort_supplements(supplements).join
    end
  end
end
