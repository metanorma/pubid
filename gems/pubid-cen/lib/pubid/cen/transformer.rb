require_relative "identifier/base"
require_relative "renderer/base"

module Pubid::Cen
  class Transformer < Parslet::Transform
    rule(incorporated_supplements: subtree(:incorporated_supplements)) do |context|
      if context[:incorporated_supplements].is_a?(Array)
        { incorporated_supplements: context[:incorporated_supplements].map do |supplement|
            convert_supplement(supplement)
          end
         }
      else
        { incorporated_supplements: [convert_supplement(context[:incorporated_supplements])] }
      end
    end

    rule(supplement: subtree(:supplement)) do |context|
      context[:supplement][:type] = convert_supplement_type(context[:supplement][:type])
      context
    end

    rule(adopted: subtree(:adopted)) do |context|
      { adopted: Pubid::Iec::Identifier.parse(context[:adopted].to_s) }
    rescue Pubid::Core::Errors::ParseError
      { adopted: Pubid::Iso::Identifier.parse(context[:adopted].to_s) }
    end

    def self.convert_supplement(supplement)
      case supplement[:type]
      when "A"
        Identifier::Amendment.new(**supplement.dup.tap { |h| h.delete(:type) })
      when "AC"
        Identifier::Corrigendum.new(**supplement.dup.tap { |h| h.delete(:type) })
      end
    end

    def self.convert_supplement_type(type)
      case type
      when "A"
        :amd
      when "AC"
        :cor
      end
    end
  end
end
