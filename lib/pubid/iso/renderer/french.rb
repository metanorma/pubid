module Pubid::Iso::Renderer
  class French < Base
    def render_typed_stage(typed_stage, opts, params)
      return nil if typed_stage.type == :guide

      super
    end

    def render_identifier(params)
      if @params[:typed_stage]&.type == :guide
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
