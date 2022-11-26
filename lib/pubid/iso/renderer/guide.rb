module Pubid::Iso::Renderer
  class Guide < Base
    def render_identifier(params)
      "%{publisher} Guide%{stage} %{number}%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{edition}" % params
    end
  end
end
