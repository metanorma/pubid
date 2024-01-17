require_relative "identifier/base"
require_relative "renderer/base"

module Pubid::Bsi
  class Transformer < Parslet::Transform
    rule(supplement: subtree(:supplement)) do |context|
      if context[:supplement][:year] && context[:supplement][:year].to_s.length == 2
        context[:supplement][:year] = if context[:supplement][:year].to_i > 50
                                        "19#{context[:supplement][:year]}"
                                      else
                                        "20#{context[:supplement][:year]}"
                                      end
      end

      { supplement:
          case context[:supplement][:type]
          when "A"
            Identifier::Amendment.new(**context[:supplement].dup.tap { |h| h.delete(:type) })
          when "C"
            Identifier::Corrigendum.new(**context[:supplement].dup.tap { |h| h.delete(:type) })
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

    rule(translation: simple(:translation)) do
      { translation: translation.to_s.downcase.capitalize }
    end
  end
end
