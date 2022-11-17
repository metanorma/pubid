module Pubid::Iso::Renderer
  class TechnicalReport < Base
    def render_identifier(params)
      type_prefix = (params[:typed_stage].nil? || params[:typed_stage].empty?) ? " TR" : ""
      "%{publisher}%{typed_stage}%{stage}#{type_prefix} %{number}%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{edition}" % params
    end
  end
end
