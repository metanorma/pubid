require_relative "urn-supplement"

module Pubid::Iso::Renderer
  class UrnCorrigendum < UrnSupplement
    TYPE = "cor".freeze

    def render_identifier(params)
      "%{base}%{stage}:cor%{year}%{number}%{edition}" \
      "#{@params[:base].language ? (':' + @params[:base].language) : ''}" % params
    end
  end
end
