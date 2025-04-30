require_relative "urn"

module Pubid::Iso::Renderer
  class UrnExtract < Urn
    def render_identifier(params)
      "%<base>s%<stage>s:ext%<year>s%<number>s%<edition>s" \
        "#{@params[:base].language ? ":#{@params[:base].language}" : ''}%<all_parts>s" % params
    end

    def render_base(base, _opts, _params)
      return base.urn if base.base || base.is_a?(Pubid::Iso::Identifier::Directives)

      # to avoid rendering language as part of base
      Urn.new(base.to_h(deep: false)).render
    end

    def render_number(number, _opts, params)
      if params[:year]
        ":v#{number}"
      else
        ":#{number}:v1"
      end
    end
  end
end
