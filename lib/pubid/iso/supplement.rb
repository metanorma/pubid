module Pubid::Iso
  class Supplement < Pubid::Core::Supplement
    def render_pubid_stage
      ((@stage && @stage) || "")
    end

    def render_urn_stage
      ((@stage && ":stage-#{sprintf('%05.2f', Pubid::Core::Renderer::Urn::STAGES[@stage.to_sym])}") || "")
    end
  end
end
