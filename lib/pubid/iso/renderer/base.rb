module Pubid::Iso::Renderer
  class Base < Pubid::Core::Renderer::Base
    def render_identifier(params)
      render_base(params, "%{type}%{stage}" % params) +
        "%{part}%{iteration}%{year}%{edition}%{amendments}%{corrigendums}%{language}" % params
    end

    def render_type(type, opts, params)
      if params[:copublisher]
        " #{type}"
      else
        "/#{type}"
      end
    end

    def render_stage(stage, opts, params)
      if params[:copublisher]
        " #{stage}"
      else
        "/#{stage}"
      end
    end

    def render_edition(edition, _opts, _params)
      " ED#{edition}"
    end

    def render_iteration(iteration, _opts, _params)
      ".#{iteration}"
    end

  end
end
