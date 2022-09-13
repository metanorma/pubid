module Pubid::Iso
  class Amendment < Supplement
    # @param stage_format [:short,:long] format for stage rendering
    def render_pubid(stage_format = :long)
      stage = render_pubid_stage
      case stage.to_s
      when "DIS"
        if stage_format == :long
          "/DAmd #{render_pubid_number}"
        else
          "/DAM #{render_pubid_number}"
        end
      when "FDIS"
        if stage_format == :long
          "/FDAmd #{render_pubid_number}"
        else
          "/FDAM #{render_pubid_number}"
        end
      when ""
        "/Amd #{render_pubid_number}"
      else
        "/#{stage} Amd #{render_pubid_number}"
      end
    end

    def render_urn
      "#{render_urn_stage}:amd#{render_urn_number}"
    end
  end
end
