module Pubid::Core
  class Corrigendum < Supplement

    def render_pubid
      stage = render_pubid_stage
      stage += " " unless stage.size == 0
      "/#{stage}Cor #{render_pubid_number}"
    end

    def render_urn
      "#{render_urn_stage}:cor#{render_urn_number}"
    end
  end
end
