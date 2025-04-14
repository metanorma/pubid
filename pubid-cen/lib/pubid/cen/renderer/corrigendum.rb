require_relative "base"

module Pubid::Cen
  module Renderer
    class Corrigendum < Pubid::Core::Renderer::Base
      def render_identifier(params)
        if params[:base].is_a?(Identifier::Base)
          "%{base}/AC%{number}%{year}" % params
        else
          "+AC%{number}%{year}" % params
        end
      end
    end
  end
end
