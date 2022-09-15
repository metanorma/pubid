module Pubid::Iso
  class Corrigendum < Supplement
    def render_pubid(stage_format_long = true, with_date = true)
      stage = render_pubid_stage
      pubid_number = render_pubid_number(with_date: with_date)
      case stage.to_s
      when "DIS"
        if stage_format_long
          "/DCor #{pubid_number}"
        else
          "/DCOR #{pubid_number}"
        end
      when "FDIS"
        if stage_format_long
          "/FDCor #{pubid_number}"
        else
          "/FDCOR #{pubid_number}"
        end
      when ""
        "/Cor #{pubid_number}"
      else
        "/#{stage} Cor #{pubid_number}"
      end
    end

    def render_urn
      "#{render_urn_stage}:cor#{render_urn_number}"
    end
  end
end
