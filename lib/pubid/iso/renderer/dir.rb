require_relative "base"

module Pubid::Iso::Renderer
  class Dir < Base

    def render_identifier(params, opts)
      if params.key?(:jtc_dir)
        res = ("%{publisher}%{dirtype}%{number} DIR%{year}%{edition}" % params)
      else
        res = ("%{publisher} DIR%{dirtype}%{number}%{year}%{edition}" % params)
      end

      if params.key?(:joint_document)
        joint_params = prerender_params(params[:joint_document].to_h(deep: false), {})
        joint_params.default = ""
        res += (" + %{publisher}%{dirtype}%{number}%{year}" % joint_params)
      end

      res
    end

    def render_number(number, _opts, _params)
      " #{number}"
    end

    def render_dirtype(dirtype, _opts, _params)
      " #{dirtype}"
    end

    def render_edition(edition, _opts, _params)
      " #{edition[:publisher]}" + (edition[:year] ? ":#{edition[:year]}" : "")
    end
  end
end
