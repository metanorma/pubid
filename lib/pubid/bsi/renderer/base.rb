module Pubid::Bsi::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE = "".freeze

    def render_identifier(params)
      return "%{publisher} %{adopted}%{supplement}%{expert_commentary}" % params unless params[:adopted].to_s.empty?

      "%{publisher} %{number}%{part}%{edition}%{year}%{month}%{supplement}%{expert_commentary}" % params
    end

    def render_month(month, _opts, _params)
      "-#{month}"
    end

    def render_edition(edition, _opts, _params)
      " v#{edition}"
    end

    def render_supplement(supplement, _opts, _params)
      supplement.to_s
    end

    def render_expert_commentary(expert_commentary, _opts, _params)
      " ExComm" if expert_commentary
    end
  end
end
