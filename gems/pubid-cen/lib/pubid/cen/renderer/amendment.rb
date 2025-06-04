require_relative "base"

module Pubid::Cen
  module Renderer
    class Amendment < Pubid::Core::Renderer::Base
      def render_identifier(params)
        if params[:base].is_a?(Identifier::Base)
          "%{base}/A%{number}%{year}" % params
        else
          "+A%{number}%{year}" % params
        end
      end
    end
  end
end
