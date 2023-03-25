require_relative "identifier/base"
require_relative "renderer/base"

module Pubid::Bsi
  class Transformer < Parslet::Transform
    rule(supplement: subtree(:supplement)) do |context|
      { supplement:
          case context[:supplement][:type]
          when "A"
            Identifier::Amendment.new(**context[:supplement])
          when "C"
            Identifier::Corrigendum.new(**context[:supplement])
          end
       }
    end
  end
end
