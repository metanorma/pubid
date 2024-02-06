module Pubid::Bsi::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE = "".freeze

    def render_identifier(params)
      suffix = "%{year}%{month}%{supplement}%{tracked_changes}%{translation}%{pdf}" % params
      unless params[:adopted].to_s.empty?
        # ignore year for adopted document if already defined for base document
        unless params[:year].empty?
          params[:adopted].year = nil
          # ignore year for adopted identifier assigned to adopted identifier
          if params[:adopted].respond_to?(:adopted) && params[:adopted].adopted
            params[:adopted].adopted.year = nil
          end
        end

        return "%{publisher} %{adopted}#{suffix}" % params
      end

      "%{publisher} %{number}%{part}%{edition}#{suffix}" % params
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

    def render_tracked_changes(tracked_changes, _opts, _params)
      " - TC" if tracked_changes
    end

    def render_translation(translation, _opts, _params)
      " (#{translation})"
    end

    def render_pdf(pdf, _opts, _params)
      " PDF" if pdf
    end
  end
end
