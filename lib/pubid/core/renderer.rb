module Pubid::Core
  class Renderer
    attr_accessor :params

    def initialize(params)
      @params = params
      @params.default = ""
    end
    # render from hash keys
    def render
      "%{publisher}%{type}%{stage} %{number}%{part}%{iteration}"\
        "%{edition}%{supplements}%{language}" % @params
    end
  end
end
