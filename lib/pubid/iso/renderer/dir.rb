module Pubid::Iso::Renderer
  class Dir < Base

    def render_identifier(params)
      res = ("%{publisher}%{copublisher} DIR%{dirtype}%{number}%{year}%{supplement}%{language}" % params)

      if params.key?(:joint_document)
        joint_params = prerender_params(params[:joint_document].get_params, {})
        joint_params.default = ""
        res += (" + %{publisher}%{copublisher}%{dirtype}%{number}%{year}%{supplement}" % joint_params)
      end

      res
    end

    def render_number(number, _opts, _params)
      " #{number}"
    end

    def render_dirtype(dirtype, _opts, _params)
      " #{dirtype}"
    end

    def render_supplement(supplement, _opts, _params)
      if supplement.publisher && supplement.publisher != ""
        " #{supplement.publisher} SUP"
      else
        " SUP"
      end + (supplement.year && ":#{supplement.year}" || "") +
        (supplement.edition && " Edition #{supplement.edition}" || "")
    end
  end
end
