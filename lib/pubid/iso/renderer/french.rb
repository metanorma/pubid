module Pubid::Iso::Renderer
  class French < Base
    def render_identifier(params)
      if params[:type] == " Guide"
        params[:type] = ""
        "Guide #{super(params)}"
      else
        super
      end
    end

    def render_copublisher(copublisher, opts, params)
      "/#{copublisher.to_s.sub("IEC", "CEI")}"
    end

    def render_corrigendums(corrigendums, _opts, _params)
      super.gsub(" ", ".")
    end

    def render_amendments(amendments, _opts, _params)
      super.gsub(" ", ".")
    end
  end
end
