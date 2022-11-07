module Pubid::Iso::Renderer
  class French < Base
    def render_typed_stage(typed_stage, opts, params)
      return nil if typed_stage.type == :guide

      super
    end

    def omit_post_publisher_symbol?(typed_stage)
      return true if typed_stage.type == :guide

      super
    end

    def render_identifier(params)
      if @params[:typed_stage]&.type == :guide
        "Guide #{super(params)}"
      else
        super
      end
    end

    # TODO: This should be only replacing a single entry called "IEC",
    # not "IECEE => CEIEE"
    def render_publisher(publisher, opts, params)
      super.sub("/IEC", "/CEI")
    end

    def render_corrigendums(corrigendums, _opts, _params)
      super.gsub(" ", ".")
    end

    def render_amendments(amendments, _opts, _params)
      super.gsub(" ", ".")
    end
  end
end
