require_relative "base"

module Pubid::Iso::Renderer
  class Dir < Base

    def render_identifier(params, opts)
      res = ("%{publisher} DIR%{dirtype}%{number}%{year}%{edition_publisher}" % params)

      if params.key?(:joint_document)
        joint_params = prerender_params(params[:joint_document].get_params, {})
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

    def render_edition_publisher(edition_publisher, _opts, _params)
      " #{edition_publisher}"
    end
  end
end
