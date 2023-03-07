module Pubid::Bsi::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE = "".freeze

    def render_identifier(params)
      "%{publisher} %{number}%{part}%{edition}%{year}%{month}" % params
    end

    def render_month(month, _opts, _params)
      "-#{month}"
    end

    def render_edition(edition, _opts, _params)
      " v#{edition}"
    end
  end
end
