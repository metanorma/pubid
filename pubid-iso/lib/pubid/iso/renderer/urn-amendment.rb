require_relative "urn-supplement"

module Pubid::Iso::Renderer
  class UrnAmendment < UrnSupplement
    TYPE = "amd".freeze

    def render_identifier(params)
      "%{base}%{stage}:amd%{year}%{number}%{edition}" \
      "#{@params[:base].language ? (':' + @params[:base].language) : ''}" % params
    end
  end
end
