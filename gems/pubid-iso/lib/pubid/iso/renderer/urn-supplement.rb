require_relative "urn"

module Pubid::Iso::Renderer
  class UrnSupplement < Urn
    TYPE = "sup".freeze

    def render_identifier(params)
      "%<base>s%<stage>s:#{self.class::TYPE}%<publisher>s%<year>s%<number>s%<edition>s" \
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

    def render_publisher(publisher, _opts, _params)
      ":#{publisher.downcase}" unless publisher.empty?
    end
  end
end
