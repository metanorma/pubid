module Pubid::Iso::Renderer
  class TechnicalSpecification < Base

    def omit_post_publisher_symbol?(_typed_stage, _stage, _opts)
      # always need post publisher symbol, because we always have to add "TR"
      false
    end

    def render_identifier(params)
      type_prefix = (params[:typed_stage].nil? || params[:typed_stage].empty?) ? "TS" : ""
      "%{publisher}%{typed_stage}%{stage}#{type_prefix} %{number}%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{edition}" % params
    end
  end
end
