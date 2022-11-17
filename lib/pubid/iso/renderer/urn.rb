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
      # @params[:type_stage] = @params.slice(:stage, :type) if @params[:stage] || @params[:type]
      super
    end

    # Render identifier
    # @param with_edition [Boolean] include edition in output
    # @see Pubid::Core::Renderer::Base for another options
    def render(with_edition: true, **args)
      # copy type from typed stage
      # @params[:type] = @params[:typed_stage].type if @params[:typed_stage] && @params[:typed_stage].type
      super(**args.merge({ with_edition: with_edition }))
    end

    def render_identifier(params)
      render_base(params) + "%{stage}"\
      "%{corrigendum_stage}%{iteration}%{edition}%{amendments}%{corrigendums}" % params
    end

    # def render_typed_stage(typed_stage, _opts, _params)
    #   ":stage-#{typed_stage.stage.harmonized_code}" if typed_stage.stage
    # end
    #
    def render_stage(stage, _opts, params)
      ":stage-#{stage.harmonized_code.to_s}"
    end

    def render_iteration(iteration, _opts, params)
      ".v#{iteration}" if params[:typed_stage]&.stage
    end

    def render_type(type, _, _)
      ":#{type.to_s.downcase}" unless type == :is
    end

    def render_year(year, _opts, _params)
      ":#{year}"
    end
  end
end
