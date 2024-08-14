module Pubid::Plateau::Renderer
  class TechnicalReport < Base
    TYPE = "Technical Report".freeze

    def render_annex(annex, _opts, _params)
      "_#{annex}"
    end
  end
end
