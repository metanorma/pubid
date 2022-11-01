module Pubid::Iso
  class Amendment < Supplement
    # @param stage_format_long [Boolean] long or short format for stage rendering
    # @param with_date [Boolean] include date
    def render_pubid(stage_format_long = true, with_date = true)
      pubid_number = render_pubid_number(with_date: with_date)

      "/#{@typed_stage.to_s(stage_format_long)} #{pubid_number}"
    end

    def render_urn
      "#{render_urn_stage}:amd#{render_urn_number}"
    end
  end
end
