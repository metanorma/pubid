module Pubid::Bsi::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE = "".freeze

    def render_identifier(params)
      suffix = "%{supplement}%{expert_commentary}%{tracked_changes}" % params
      prefix = "%{national_annexes}" % params
      return "#{prefix}%{publisher} %{adopted}#{suffix}" % params unless params[:adopted].to_s.empty?

      "#{prefix}%{publisher} %{number}%{part}%{edition}%{year}%{month}#{suffix}" % params
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

    def render_national_annexes(national_annexes, _opts, _params)
      if national_annexes.is_a?(Hash)
        "NA#{national_annexes[:supplement]} to "
      else
        "NA to "
      end
    end
  end
end
