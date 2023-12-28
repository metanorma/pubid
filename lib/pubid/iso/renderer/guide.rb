require_relative "base"

module Pubid::Iso::Renderer
  class Guide < Base
    def render_identifier(params, opts)
      if opts[:language] == :french
        "Guide %{publisher}%{stage} %{number}%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{edition}" % params
      elsif opts[:language] == :russian
        "Руководство %{publisher}%{stage} %{number}%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{edition}" % params
      else
        if params[:stage] && params[:stage].is_a?(Pubid::Core::TypedStage)
          "%{publisher}%{stage} %{number}%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{edition}" % params
        else
          "%{publisher}%{stage} Guide %{number}%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{edition}" % params
        end
      end
    end
  end
end
