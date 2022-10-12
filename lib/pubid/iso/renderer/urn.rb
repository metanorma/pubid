module Pubid::Iso::Renderer
  class Urn < Pubid::Core::Renderer::Urn
    STAGES = { PWI: 0,
               NP: 10,
               AWI: 20,
               WD: 20.20,
               CD: 30,
               DIS: 40,
               FDIS: 50,
               PRF: 50,
               IS: 60 }.freeze

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

    def render_without_year(with_edition: true, **args)
      prerender(with_edition: with_edition, **args)

      # render empty string when the key is not exist
      @prerendered_params.default = ""

      render_identifier(@prerendered_params)
    end
    def render_supplement(supplement_params, **args)
      if supplement_params[:base].type == :amd
        render_supplement(supplement_params[:base].get_params, **args)
      else
        self.class.new(supplement_params[:base].get_params).render_without_year
      end +
        case supplement_params[:type]
        when :amd
          render_amendments(
            [Pubid::Iso::Amendment.new(**supplement_params.slice(:number, :year, :stage, :edition, :iteration))],
            args,
            nil,
            )
        when :cor
          render_corrigendums(
            [Pubid::Iso::Corrigendum.new(**supplement_params.slice(:number, :year, :stage, :edition, :iteration))],
            args,
            nil,
            )
          # copy parameters from Identifier only supported by Corrigendum
        end
    end

    # Render identifier
    # @param with_edition [Boolean] include edition in output
    # @see Pubid::Core::Renderer::Base for another options
    def render(with_edition: true, **args)
      if %i(amd cor).include? @params[:type]
        render_supplement(@params, with_edition: with_edition, **args) +
          (@params[:base].language ? render_language(@params[:base].language, nil, nil).to_s : "")
      else
        prerender(with_edition: with_edition, **args)

        # render empty string when the key is not exist
        @prerendered_params.default = ""

        render_identifier(@prerendered_params) + @prerendered_params[:language]
      end
    end

    def render_identifier(params)
      render_base(params) + "%{stage}"\
      "%{corrigendum_stage}%{iteration}%{edition}%{amendments}%{corrigendums}" % params
    end

    def render_stage(stage, _opts, params)
      ":stage-#{stage.harmonized_code}"
    end
  end
end
