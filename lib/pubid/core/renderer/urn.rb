module Pubid::Core::Renderer
  class Urn < Base

    def render_base(params)
      "urn:iso:std:%{publisher}%{copublisher}%{type}:%{number}%{part}" % params
    end

    def render_identifier(params)
      render_base(params)
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
