module Pubid::Itu::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE_PREFIX = "".freeze

    def render(**args)
      render_base_identifier(**args) + @prerendered_params[:language].to_s
    end

    def render_identifier(params)
      "%{publisher}-%{sector} %{type}%{series}%{number}%{part}%{month}%{year}" % params
    end

    def render_month(month, _opts, _params)
      " (#{month}"
    end

    def render_year(year, _opts, params)
      return " (#{year})" unless params[:month]

      "/#{year})"
    end

    def render_type(type, opts, _params)
      "#{type}-" if opts[:with_type]
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
