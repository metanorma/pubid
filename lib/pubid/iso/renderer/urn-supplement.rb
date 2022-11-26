module Pubid::Iso::Renderer
  class UrnSupplement < Urn
    def render_identifier(params)
      "%{base}%{stage}:#{self.class::TYPE}%{year}%{number}" \
      "#{@params[:base].language ? (':' + @params[:base].language) : ''}" % params
    end

    def render_base(base, _opts, _params)
      return base.urn if base.base

      # to avoid rendering language as part of base
      Urn.new(base.get_params).render
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
