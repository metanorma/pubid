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

    def render_identifier(params)
      render_base(params) + "%{stage}"\
      "%{urn_stage}%{corrigendum_stage}%{iteration}%{edition}%{amendments}%{corrigendums}%{language}" % params
    end

    def render_stage(stage, _opts, params)
      return if params[:urn_stage]

      return ":stage-#{sprintf('%05.2f', stage)}" if stage.is_a?(Float)

      ":stage-#{sprintf('%05.2f', STAGES[stage.to_sym])}"
    end

    def render_urn_stage(stage, opts, params)
      ":stage-#{sprintf('%05.2f', stage)}"
    end
  end
end
