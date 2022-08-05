module Pubid::Core::Renderer
  class Urn < Base
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
      "urn:iso:std:%{publisher}%{copublisher}%{type}:%{number}%{part}%{stage}"\
      "%{urn_stage}%{corrigendum_stage}%{iteration}%{edition}%{amendments}%{corrigendums}%{language}" % params
    end

    def render_publisher(publisher, _opts, _params)
      publisher.downcase
    end

    def render_copublisher(copublisher, _opts, _params)
      return "-#{copublisher.to_s.downcase}" unless copublisher.is_a?(Array)

      copublisher.map(&:to_s).sort.map do |copublisher|
        "-#{copublisher.downcase}"
      end.join
    end

    def render_edition(edition, _opts, _params)
      ":ed-#{edition}"
    end

    def render_type(type, _, _)
      ":#{type.downcase}"
    end

    def render_amendments(amendments, _opts, _params)
      amendments&.map(&:render_urn)&.join || ""
    end

    def render_corrigendums(corrigendums, _opts, _params)
      corrigendums&.map(&:render_urn)&.join || ""
    end

    def render_language(language, _opts, _params)
      ":#{language}"
    end

    def render_stage(stage, _opts, _params)
      return ":stage-#{sprintf('%05.2f', stage)}" if stage.is_a?(Float)

      ":stage-#{sprintf('%05.2f', STAGES[stage.to_sym])}"
    end

    def render_urn_stage(stage, opts, params)
      render_stage(stage, opts, params)
    end

    def render_corrigendum_stage(stage, opts, params)
      render_stage(stage, opts, params)
    end

    def render_iteration(iteration, _opts, params)
      ".v#{iteration}" if params[:stage]
    end

    def render_part(part, _opts, _params)
      ":-#{part}"
    end
  end
end
