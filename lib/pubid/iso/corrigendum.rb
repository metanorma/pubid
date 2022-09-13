module Pubid::Iso
  class Corrigendum < Supplement
    def render_pubid(stage_format = :long)
      stage = render_pubid_stage
      case stage.to_s
      when "DIS"
        if stage_format == :long
          "/DCor #{render_pubid_number}"
        else
          "/DCOR #{render_pubid_number}"
        end
      when "FDIS"
        if stage_format == :long
          "/FDCor #{render_pubid_number}"
        else
          "/FDCOR #{render_pubid_number}"
        end
      when ""
        "/Cor #{render_pubid_number}"
      else
        "/#{stage} Cor #{render_pubid_number}"
      end
    end

    def render_urn
      "#{render_urn_stage}:cor#{render_urn_number}"
    end
  end
end
