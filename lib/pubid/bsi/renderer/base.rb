module Pubid::Bsi::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE = "".freeze

    def render_identifier(params)
      "%{publisher} %{number}%{part}%{year}" % params
    end
  end
end
