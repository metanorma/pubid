require_relative "base"

module Pubid::Bsi::Renderer
  class NationalAnnex < Base

    def render_identifier(params)
      "NA%{supplement} to %{base}" % params
    end
  end
end
