require_relative "base"

module Pubid::Iso::Renderer
  class InternationalWorkshopAgreement < Base
    def omit_post_publisher_symbol?(_typed_stage, _stage, _opts)
      # always need post publisher symbol, because we always have to add "TR"
      false
    end

    def render_identifier(params, opts)
      type_prefix = (params[:typed_stage].nil? || params[:typed_stage].empty?) ? "IWA" : ""

      type_prefix = " #{type_prefix}" if params[:stage] && !params[:stage].empty?

      "%{typed_stage}%{stage}#{type_prefix} %{number}%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{edition}" % params
    end
  end
end
