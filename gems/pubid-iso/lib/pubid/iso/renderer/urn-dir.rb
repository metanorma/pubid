require_relative "urn"

module Pubid::Iso::Renderer
  class UrnDir < Urn
    def render_identifier(params) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      res = ("urn:iso:doc:%<publisher>s%<copublisher>s:dir%<dirtype>s%<number>s%<year>s%<supplement>s" % params)

      if params.key?(:joint_document)
        if params[:joint_document].is_a?(Pubid::Iso::Identifier::Supplement)
          joint_params = params[:joint_document].to_h(deep: false)
          res += ":#{joint_params[:base].publisher.downcase}:sup:%<year>s" % joint_params
        else
          joint_params = prerender_params(params[:joint_document].to_h(deep: false), {})
          joint_params.default = ""
          res += (":%<publisher>s%<copublisher>s%<dirtype>s%<number>s%<supplement>s" % joint_params)
        end

      end

      res + params[:all_parts]
    end

    def render_number(number, _opts, _params)
      ":#{number}"
    end

    def render_dirtype(dirtype, _opts, _params)
      ":#{dirtype.downcase}"
    end

    def render_supplement(supplement, _opts, _params) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      if supplement.publisher && supplement.publisher != ""
        ":sup:#{supplement.publisher.downcase}"
      else
        ":sup"
      end + (supplement.year && ":#{supplement.year}" || "") +
        (supplement.edition && ":ed-#{supplement.edition}" || "")
    end
  end
end
