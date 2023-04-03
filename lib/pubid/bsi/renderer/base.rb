module Pubid::Bsi::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE = "".freeze

    def render_identifier(params)
      return "%{publisher} %{adopted}%{supplement}" % params unless params[:adopted].to_s.empty?

      "%{publisher} %{number}%{part}%{edition}%{year}%{month}%{supplement}" % params
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
