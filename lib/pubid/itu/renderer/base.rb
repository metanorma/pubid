module Pubid::Itu::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE = "".freeze

    def render(**args)
      render_base_identifier(**args) + @prerendered_params[:language].to_s
    end

    def render_identifier(params)
      "%{publisher}-%{sector} %{series}%{number}%{part}" % params
    end

    def render_part(part, opts, _params)
      return "-#{part.reverse.join('-')}" if part.is_a?(Array)

      "-#{part}"
    end

    def render_series(series, _opts, _params)
      "#{series}."
    end
  end
end
