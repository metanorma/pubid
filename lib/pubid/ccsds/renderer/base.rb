module Pubid::Ccsds::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE = "".freeze

    def render_identifier(params)
      "%{publisher} %{number}%{part}%{type}%{edition}" % params
    end

    def render_part(part, _opts, _params)
      ".#{part}"
    end

    def render_type(type, _opts, _params)
      "-#{type}"
    end

    def render_edition(edition, _opts, _params)
      "-#{edition}"
    end
  end
end
