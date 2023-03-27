module Pubid::Bsi::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE = "".freeze

    def render_identifier(params)
      "%{publisher} %{adopted}%{number}%{part}%{edition}%{year}%{month}%{supplement}" % params
    end

    def render_month(month, _opts, _params)
      "-#{month}"
    end

    def render_edition(edition, _opts, _params)
      " v#{edition}"
    end

    def render_supplement(supplement, _opts, _params)
      supplement.to_s
    end
  end
end
