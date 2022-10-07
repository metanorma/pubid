module Pubid::Iso::Renderer
  class Base < Pubid::Core::Renderer::Base
    attr_accessor :prerendered_params

    TYPE_VALUES = {
      tr: "TR",
      ts: "TS",
      isp: "ISP",
      guide: "Guide",
      pas: "PAS",
      dpas: "DPAS",
    }.freeze

    # Prerender parameters
    def prerender(with_edition: true, **args)
      @prerendered_params =
        if @params[:stage] || @params[:type]
          prerender_params(@params.merge({ type_stage: @params.slice(:stage, :type) }),
                           { with_edition: with_edition }.merge(args))
        else
          prerender_params(@params,
                           { with_edition: with_edition }.merge(args))
        end

      self
    end

    # Render identifier
    # @param with_edition [Boolean] include edition in output
    # @see Pubid::Core::Renderer::Base for another options
    def render(with_edition: true, **args)
      case @params[:type]
      when :amd
        @params[:base].to_s +
          # copy parameters from Identifier only supported by Amendment
          Pubid::Iso::Amendment.new(
            **@params.slice(:number, :year, :stage, :edition, :iteration)
          ).render_pubid(args[:stage_format_long], args[:with_date])
      when :cor
        @params[:base].to_s +
          # copy parameters from Identifier only supported by Corrigendum
          Pubid::Iso::Corrigendum.new(
            **@params.slice(:number, :year, :stage, :edition, :iteration)
          ).render_pubid(args[:stage_format_long], args[:with_date])
      else
        prerender(with_edition: with_edition, **args)

        # render empty string when the key is not exist
        @prerendered_params.default = ""

        render_identifier(@prerendered_params)
      end
    end

    def render_identifier(params)
      type_stage = if params[:type_stage] && !params[:type_stage].empty?
                     ((params[:copublisher] && !params[:copublisher].empty?) ? " " : "/") + params[:type_stage]
                   else
                     ""
                   end
      render_base(params, type_stage) +
        ("%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{edition}%{language}" % params)
    end

    def render_type_stage(values, opts, params)
      # prerender stage and type before
      stage = render_stage(values[:stage], opts, params)
      type = values[:type] ? TYPE_VALUES[values[:type]] : nil
      return unless type || stage

      if type && stage
        # don't add prefix for pdf format
        if %w(DIS FDIS).include?(stage)
          "#{render_short_stage(stage)}#{type}"
        else
          "#{stage} #{type}"
        end
      else
        # when only type or stage
        "#{type}#{stage}"
      end
    end

    def render_short_stage(stage)
      case stage
      when "DIS"
        "D"
      when "FDIS"
        "FD"
      end
    end

    def render_stage(stage, opts, _params)
      return if stage.nil? || (stage.abbr == "PRF" and !opts[:with_prf]) || stage.abbr == "IS"

      stage.abbr
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
