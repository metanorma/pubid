module Pubid::Itu::Renderer
  class SpecialPublication < Base
    def render_number(number, _opts, params)
      " No. #{number}"
    end
  end
end
