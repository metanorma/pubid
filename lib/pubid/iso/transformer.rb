module Pubid::Iso
  class Transformer < Parslet::Transform
    rule(edition: "Ed") do
      { edition: "1" }
    end

    rule(stage: subtree(:stage)) do |context|
      stage_and_type = convert_stage(context[:stage])
      context[:stage] = stage_and_type[:stage]
      context[:type] = stage_and_type[:type] if stage_and_type[:type]
      context
    end

    rule(supplements: subtree(:supplements)) do |context|
      context[:supplements] =
        context[:supplements].map do |supplement|
          supplement.merge(
            case supplement[:typed_stage]
            when "PDAM"
              { typed_stage: "CD", type: "Amd" }
            when "pDCOR"
              { typed_stage: "CD", type: "Cor" }
            when "FPDAM"
              { typed_stage: "DAM" }
            when "FDAmd"
              { typed_stage: "FDAM" }
            when "FDCor"
              { typed_stage: "FCOR" }
            else
              {}
            end
          )
        end
      context
    end

    rule(amendments: subtree(:amendments)) do |context|
      context[:amendments] =
        context[:amendments].map do |amendment|
          Amendment.new(
            number: amendment[:number],
            year: amendment[:year],
            typed_stage: amendment[:stage] && convert_stage(amendment[:stage]),
            iteration: amendment[:iteration])
        end
      context
    end

    rule(corrigendums: subtree(:corrigendums)) do |context|
      context[:corrigendums] =
        context[:corrigendums].map do |corrigendum|
          Corrigendum.new(
            number: corrigendum[:number],
            year: corrigendum[:year],
            typed_stage: corrigendum[:stage] && convert_stage(corrigendum[:stage]),
            iteration: corrigendum[:iteration])
        end
      context
    end

    rule(language: simple(:language)) do |context|
      if context[:language].to_s.include?("/")
        { language: context[:language]
          .to_s.split("/")
          .map { |code| convert_language(code) }.join(",") }
      else
        { language: convert_language(context[:language]) }
      end
    end

    rule(type: simple(:type)) do
      russian_type = Renderer::Russian::TYPE.key(type.to_s)
      { type: russian_type&.downcase&.to_sym ||
                        case type
                        # XXX: can't put 2 alternative Russian translations to dictionary, temporary hack
                        when "GUIDE", "Guide", "Руководства"
                          :guide
                        when "ТС", "TS"
                          :ts
                        when "ТО", "TR"
                          :tr
                        when "Directives Part", "Directives, Part", "Directives,", "DIR"
                          :dir
                        when "PAS"
                          :pas
                        when "DPAS"
                          :dpas
                        when "R"
                          :r
                        else
                          type
                        end }
    end

    rule(copublisher: simple(:copublisher)) do
      russian_copublisher = Renderer::Russian::PUBLISHER.key(copublisher.to_s)
      { copublisher: russian_copublisher&.to_s ||
        case copublisher
        when "CEI"
          "IEC"
        else
          copublisher.to_s
        end
      }
    end

    rule(publisher: simple(:publisher)) do
      russian_publisher = Renderer::Russian::PUBLISHER.key(publisher.to_s)
      { publisher: russian_publisher&.to_s || publisher }
    end

    rule(publisher: simple(:publisher), supplement: subtree(:supplement)) do |context|
      context[:supplement] =
        Supplement.new(number: context[:supplement][:number],
                       year: context[:supplement][:year],
                       publisher: context[:supplement][:publisher],
                       edition: context[:supplement][:edition])
      context
    end

    rule(supplement: subtree(:supplement)) do |context|
      context[:supplement] =
        Supplement.new(number: context[:supplement][:number],
                       year: context[:supplement][:year],
                       publisher: context[:supplement][:publisher],
                       edition: context[:supplement][:edition])
      context
    end

    rule(joint_document: subtree(:joint_document)) do |context|
      context[:joint_document] =
        Identifier.new(**context[:joint_document])
      context
    end

    def self.convert_stage(code)
      russian_code = Renderer::Russian::STAGE.key(code.to_s)
      return { stage: russian_code } if russian_code

      case code
      when "NWIP"
        { stage: "NP" }
      when "D", "FPD"
        { stage: "DIS" }
      when "FD", "F"
        { stage: "FDIS" }
      when "Fpr"
        { stage: "PRF" }
      when "PDTR"
        { stage: "CD", type: "TR" }
      when "PDTS"
        { stage: "CD", type: "TS" }
      else
        { stage: code }
      end
    end

    def self.convert_language(code)
      case code
      when "R"
        "ru"
      when "F"
        "fr"
      when "E"
        "en"
      when "A"
        "ar"
      else
        code
      end
    end
  end
end
