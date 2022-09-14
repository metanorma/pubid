module Pubid::Iso
  class Amendment < Supplement
    # @param stage_format [:short,:long] format for stage rendering
    # @param with_date [Boolean] include date
    def render_pubid(stage_format = :long, with_date = true)
      stage = render_pubid_stage
      pubid_number = render_pubid_number(with_date: with_date)
      case stage.to_s
      when "DIS"
        if stage_format == :long
          "/DAmd #{pubid_number}"
        else
          "/DAM #{pubid_number}"
        end
      when "FDIS"
        if stage_format == :long
          "/FDAmd #{pubid_number}"
        else
          "/FDAM #{pubid_number}"
        end
      when ""
        "/Amd #{pubid_number}"
      else
        "/#{stage} Amd #{pubid_number}"
      end
    end

    def render_urn
      "#{render_urn_stage}:amd#{render_urn_number}"
    end
  end
end
