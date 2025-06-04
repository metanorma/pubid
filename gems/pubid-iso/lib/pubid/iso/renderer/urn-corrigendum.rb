require_relative "urn-supplement"

module Pubid::Iso::Renderer
  class UrnCorrigendum < UrnSupplement
    TYPE = "cor".freeze

    def render_identifier(params)
      "%<base>s%<stage>s:cor%<year>s%<number>s%<edition>s" \
      "#{@params[:base].language ? ":#{@params[:base].language}" : ''}%<all_parts>s" % params
    end
  end
end
