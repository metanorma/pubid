require_relative "base"

module Pubid::Iso::Renderer
  class InternationalWorkshopAgreement < Base

    TYPE = "IWA".freeze

    def omit_post_publisher_symbol?(_typed_stage, _stage, _opts)
      # always need post publisher symbol, because we always have to add "TR"
      false
    end

    def render_identifier(params, opts)
      "%{typed_stage}%{stage}#{render_type_prefix(params)} %{number}%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{addendum}%{edition}" % params
    end
  end
end
