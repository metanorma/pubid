require_relative "urn-supplement"

module Pubid::Iso::Renderer
  class UrnAmendment < UrnSupplement
    TYPE = "amd".freeze

    def render_identifier(params)
      "%<base>s%<stage>s:amd%<year>s%<number>s%<edition>s" \
      "#{@params[:base].language ? ":#{@params[:base].language}" : ''}%<all_parts>s" % params
    end
  end
end
