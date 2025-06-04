require_relative "base"

module Pubid::Iso::Renderer
  class InternationalWorkshopAgreement < Base

    TYPE = "IWA".freeze

    def omit_post_publisher_symbol?(_typed_stage, _stage, _opts)
      # always need post publisher symbol, because we always have to add "TR"
      false
    end

    def render_identifier(params, opts)
      stage = params.key?(:stage) ? postrender_stage(params[:stage], opts, params) : ""
      "#{stage}#{render_type_prefix(params, opts)} %{number}%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{addendum}%{edition}" % params
    end
  end
end
