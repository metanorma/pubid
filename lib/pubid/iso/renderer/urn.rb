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
      "%{corrigendum_stage}%{iteration}%{edition}%{amendments}%{corrigendums}%{language}" % params
    end

    def render_stage(stage, _opts, params)
      ":stage-#{stage.harmonized_code}"
    end
  end
end
