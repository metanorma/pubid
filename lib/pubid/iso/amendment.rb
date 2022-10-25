module Pubid::Iso
  class Amendment < Supplement
    # @param stage_format_long [Boolean] long or short format for stage rendering
    # @param with_date [Boolean] include date
    def render_pubid(stage_format_long = true, with_date = true)
      # stage = render_pubid_stage
      pubid_number = render_pubid_number(with_date: with_date)
      # case @typed_stage.to_s(stage_format_long)
      # when "DIS"
      #   if stage_format_long
      #     "/DAmd #{pubid_number}"
      #   else
      #     "/DAM #{pubid_number}"
      #   end
      # when "FDIS"
      #   if stage_format_long
      #     "/FDAmd #{pubid_number}"
      #   else
      #     "/FDAM #{pubid_number}"
      #   end
      # when "CD"
      #   if stage_format_long
      #     "/CD Amd #{pubid_number}"
      #   else
      #     "/CDAM #{pubid_number}"
      #   end
      # when ""
      #   "/Amd #{pubid_number}"
      # else
      "/#{@typed_stage.to_s(stage_format_long)} #{pubid_number}"
      # end
    end

    def render_urn
      "#{render_urn_stage}:amd#{render_urn_number}"
    end
  end
end
