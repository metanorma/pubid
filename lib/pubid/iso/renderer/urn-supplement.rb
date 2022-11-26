module Pubid::Iso::Renderer
  class UrnSupplement < Urn
    def render_identifier(params)
      "%{base}%{stage}:#{self.class::TYPE}%{year}:v%{number}" \
      "#{@params[:base].language ? (':' + @params[:base].language) : ''}" % params
    end

    def render_base(base, _opts, _params)
      return base.urn if base.base

      # to avoid rendering language as part of base
      Urn.new(base.get_params).render
    end
  end
end
