module Pubid::Iso::Renderer
  class UrnDir < Pubid::Core::Renderer::Urn

    def render_identifier(params)
      res = ("urn:iso:doc:%{publisher}%{copublisher}:dir%{dirtype}%{number}%{year}%{supplement}" % params)

      if params.key?(:joint_document)
        joint_params = prerender_params(
          params[:joint_document].transform_values { |value| value.is_a?(Parslet::Slice) && value.to_s || value }, {}
        )
        joint_params.default = ""
        res += (":%{publisher}%{copublisher}%{dirtype}%{number}%{supplement}" % joint_params)
      end

      res
    end

    def render_number(number, _opts, _params)
      ":#{number}"
    end

    def render_dirtype(dirtype, _opts, _params)
      ":#{dirtype.downcase}"
    end

    def render_supplement(supplement, _opts, _params)
      if supplement.publisher && supplement.publisher != ""
        ":sup:#{supplement.publisher.downcase}"
      else
        ":sup"
      end + (supplement.number && ":#{supplement.number}" || "") +
        (supplement.edition && ":ed-#{supplement.edition}" || "")
    end
  end
end
