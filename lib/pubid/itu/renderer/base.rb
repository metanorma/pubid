module Pubid::Itu::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE_PREFIX = "".freeze

    def render(**args)
      render_base_identifier(**args) + @prerendered_params[:language].to_s
    end

    def render_type_series(params)
      "%{type}%{series}" % params
    end

    def render_identifier(params)
      "%{publisher}-%{sector} #{render_type_series(params)}%{number}%{subseries}"\
      "%{part}%{second_number}%{range}%{annex}%{amendment}%{corrigendum}%{supplement}"\
      "%{addendum}%{date}" % params
    end

    def render_number(number, _opts, params)
      params[:series] ? ".#{number}" : number
    end

    def render_date(date, opts, _params)
      return if opts[:without_date]

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
      " Amd #{amendment[:number]}"
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

    def render_supplement(supplement, _opts, _params)
      " Suppl. #{supplement[:number]}"
    end

    def render_annex(annex, _opts, _params)
      " Annex #{annex[:number]}"
    end

    def render_corrigendum(corrigendum, opts, params)
      "#{render_date(corrigendum[:date], opts, params)} Cor. #{corrigendum[:number]}"
    end

    def render_range(range, _opts, params)
      "-#{params[:series]}.#{range[:number]}"
    end

    def render_addendum(addendum, opts, params)
      "#{render_date(addendum[:date], opts, params)} Add. #{addendum[:number]}"
    end
  end
end
