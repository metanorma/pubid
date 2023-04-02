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

    rule(adopted: subtree(:adopted)) do |context|
      { adopted: Pubid::Iec::Identifier.parse(context[:adopted].to_s) }
    rescue Pubid::Core::Errors::ParseError
      begin
      { adopted: Pubid::Iso::Identifier.parse(context[:adopted].to_s) }
      rescue Pubid::Core::Errors::ParseError
        { adopted: Pubid::Cen::Identifier.parse(context[:adopted].to_s) }
      end
    end
  end
end
