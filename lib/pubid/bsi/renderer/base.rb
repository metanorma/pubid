module Pubid::Bsi::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE = "".freeze

    def render_identifier(params)
      suffix = "%{supplement}%{expert_commentary}%{tracked_changes}%{translation}" % params
      return "%{publisher} %{adopted}#{suffix}" % params unless params[:adopted].to_s.empty?

      "%{publisher} %{number}%{part}%{edition}%{year}%{month}#{suffix}" % params
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

    def render_tracked_changes(tracked_changes, _opts, _params)
      " - TC" if tracked_changes
    end

    def render_translation(translation, _opts, _params)
      " (#{translation})"
    end
  end
end
