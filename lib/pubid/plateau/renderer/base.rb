module Pubid::Plateau::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE = "".freeze

    def render_identifier(params)
      "%{publisher} #{self::class::TYPE} #%{number}%{annex}%{edition}" % params
    end

    def render_number(number, _opts, _params)
      "%02d" % number.to_i
    end

    def render_annex(annex, _opts, _params)
      "-#{annex}"
    end

    def render_edition(edition, _opts, _params)
      " 第#{edition}版"
    end
  end
end
