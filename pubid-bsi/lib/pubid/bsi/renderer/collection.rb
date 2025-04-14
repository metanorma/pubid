module Pubid::Bsi::Renderer
  class Collection < Pubid::Core::Renderer::Base
    def render_identifier(params)
      "%{identifiers}%{year}%{supplement}" % params
    end

    def render_supplement(supplement, _opts, _params)
      supplement.to_s
    end

    def render_identifiers(identifiers, _opts, _params)
      "#{identifiers.first}/" + identifiers[1..-1].map(&:number).join("/")
    end
  end
end
