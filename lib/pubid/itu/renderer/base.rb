module Pubid::Itu::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE_PREFIX = "".freeze

    def render(**args)
      render_base_identifier(**args) + @prerendered_params[:language].to_s
    end

    def render_identifier(params)
      "%{publisher}-%{sector} %{type}%{series}%{number}%{subseries}%{part}%{second_number}%{amendment}%{date}" % params
    end

    def render_number(number, _opts, params)
      params[:series] ? ".#{number}" : number
    end

    def render_date(date, _opts, _params)
      return " (#{date[:year]})" unless date[:month]

      " (%<month>02d/%<year>d)" % date
    end

    def render_type(type, opts, _params)
      "#{type}-" if opts[:with_type]
    end

    def render_part(part, opts, _params)
      return "-#{part.reverse.join('-')}" if part.is_a?(Array)

      "-#{part}"
    end

    def render_series(series, _opts, _params)
      "#{series}"
    end

    def render_amendment(amendment, _opts, _params)
      " #{amendment}"
    end

    def render_subseries(subseries, _opts, _params)
      ".#{subseries}"
    end

    def render_second_number(second_number, _opts, _params)
      result = "/#{second_number[:series]}.#{second_number[:number]}"
      if second_number[:subseries]
        result += ".#{second_number[:subseries]}"
      end
      if second_number[:part]
        result += "-#{second_number[:part]}"
      end

      result
    end
  end
end
