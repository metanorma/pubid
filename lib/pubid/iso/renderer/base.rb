module Pubid::Iso::Renderer
  class Base < Pubid::Core::Renderer::Base
    # Render identifier
    # @param with_edition [Boolean] include edition in output
    # @see Pubid::Core::Renderer::Base for another options
    def render(with_edition: true, **args)
      params = prerender_params(@params,
                                { with_edition: with_edition }.merge(args))
      # render empty string when the key is not exist
      params.default = ""

      render_identifier(params)
    end

    def render_identifier(params)
      if @params[:type] && @params[:stage]
        if %w(DIS FDIS).include?(@params[:stage].abbr)
          render_base(params, "#{render_short_stage(@params[:stage].abbr)}#{@params[:type]}")
        else
          if params[:copublisher] && !params[:copublisher].empty?
            render_base(params, "%{type}%{stage}" % params)
          else
            render_base(params, "%{stage}%{type}" % params)
          end
        end
      else
        render_base(params, "%{type}%{stage}" % params)
      end +
        "%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{edition}%{language}" % params
    end

    def render_short_stage(stage)
      (params[:copublisher] ? " " : "/") +
        case stage
        when "DIS"
          "D"
        when "FDIS"
          "FD"
        end
    end

    def render_type(type, opts, params)
      if params[:copublisher]
        " #{type}"
      else
        "/#{type}"
      end
    end

    def render_stage(stage, opts, params)
      return if stage.abbr == "PRF" and !opts[:with_prf]

      if params[:copublisher]
        " #{stage.abbr}"
      else
        "/#{stage.abbr}"
      end
    end

    def render_edition(edition, opts, _params)
      " ED#{edition}" if opts[:with_edition]
    end

    def render_iteration(iteration, _opts, _params)
      ".#{iteration}"
    end

    def render_amendments(amendments, opts, _params)
      amendments.sort.map { |amendment| amendment.render_pubid(opts[:stage_format_long], opts[:with_date]) }.join("+")
    end

    def render_corrigendums(corrigendums, opts, _params)
      corrigendums.sort.map { |corrigendum| corrigendum.render_pubid(opts[:stage_format_long], opts[:with_date]) }.join("+")
    end

    def render_language(language, opts, _params)
      return if opts[:with_language_code] == :none
      super
    end

    def render_year(year, opts, params)
      return ":#{year}" if params[:amendments] || params[:corrigendums]
      opts[:with_date] && ":#{year}" || ""
    end
  end
end
