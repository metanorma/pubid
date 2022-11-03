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
      @params[:type_stage] = @params.slice(:stage, :type) if @params[:stage] || @params[:type]
      super
    end

    def render_supplement(supplement_params, **args)
      if supplement_params[:base].type == :amd
        # render inner amendment (cor -> amd -> base)
        render_supplement(supplement_params[:base].get_params, **args)
      else
        self.class.new(supplement_params[:base].get_params).render_base_identifier(
          # always render year for identifiers with supplement
          **args.merge({ with_date: true }),
          )
      end +
        case supplement_params[:typed_stage].type.type
        when :amd
          render_amendments(
            [Pubid::Iso::Amendment.new(**supplement_params.slice(:number, :year, :typed_stage, :edition, :iteration))],
            args,
            nil,
            )
        when :cor
          render_corrigendums(
            [Pubid::Iso::Corrigendum.new(**supplement_params.slice(:number, :year, :typed_stage, :edition, :iteration))],
            args,
            nil,
            )
          # copy parameters from Identifier only supported by Corrigendum
        end +
        (supplement_params[:base].language ? render_language(supplement_params[:base].language, args, nil) : "")
    end

    # Render identifier
    # @param with_edition [Boolean] include edition in output
    # @see Pubid::Core::Renderer::Base for another options
    def render(with_edition: true, with_language_code: :iso, with_date: true, **args)
      # super(**args.merge({ with_edition: with_edition }))
      if %i(amd cor).include? @params[:typed_stage]&.type&.type
        render_supplement(@params, **args.merge({ with_date: with_date,
                                                  with_language_code: with_language_code,
                                                  with_edition: with_edition }))
      else
        render_base_identifier(**args.merge({ with_date: with_date,
                                              with_language_code: with_language_code,
                                              with_edition: with_edition })) +
          @prerendered_params[:language].to_s
      end

    end

    def render_identifier(params)
      # typed_stage = if params[:typed_stage] && params[:typed_stage] != ""
      #                 ((params[:copublisher] && !params[:copublisher].empty?) ? " " : "/") + params[:typed_stage].to_s
      #               else
      #                 ""
      #               end
      render_base(params, params[:typed_stage]) +
        ("%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{edition}" % params)
    end

    def render_typed_stage(typed_stage, _opts, params)
      return nil if typed_stage.to_s.empty?

      (params[:copublisher] ? " " : "/") + typed_stage.to_s
    end

    # def render_type_stage(values, opts, params)
    #
    #   # prerender stage and type before
    #   stage = render_stage(values[:stage], opts, params)
    #   type = values[:type]&.to_s
    #   return unless type || stage
    #
    #   if type && stage
    #     # don't add prefix for pdf format
    #     if %w(DIS FDIS).include?(stage)
    #       "#{render_short_stage(stage)}#{type}"
    #     else
    #       "#{stage} #{type}"
    #     end
    #   else
    #     # when only type or stage
    #     "#{type}#{stage}"
    #   end
    # end

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
