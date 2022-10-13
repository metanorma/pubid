module Pubid::Iso
  class Transformer < Parslet::Transform
    rule(edition: "Ed") do
      { edition: "1" }
    end

    rule(stage: simple(:stage)) do |context|
      { stage: convert_stage(context[:stage]) }
    end

    rule(amendments: subtree(:amendments)) do |context|
      context[:amendments] =
        context[:amendments].map do |amendment|
          Amendment.new(
            number: amendment[:number],
            year: amendment[:year],
            stage: amendment[:stage] && convert_stage(amendment[:stage]),
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
            stage: corrigendum[:stage] && convert_stage(corrigendum[:stage]),
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
      { type: Type.new(russian_type&.downcase&.to_sym ||
                        case type
                        # XXX: can't put 2 alternative Russian translations to dictionary, temporary hack
                        when "GUIDE", "Guide", "Руководства"
                          :guide
                        when "ТС", "TS"
                          :ts
                        when "ТО", "TR"
                          :tr
                        when "Directives Part", "Directives, Part", "Directives,"
                          :dir
                        when "PAS"
                          :pas
                        when "DPAS"
                          :dpas
                        when "DIR"
                          :dir
                        else
                          type
                        end) }
    end

    rule(copublisher: simple(:copublisher)) do
      russian_copublisher = Renderer::Russian::PUBLISHER.key(copublisher.to_s)
      { copublisher: russian_copublisher&.to_s ||
        case copublisher
        when "CEI"
          "IEC"
        else
          copublisher
        end
      }
    end

    rule(publisher: simple(:publisher)) do
      russian_publisher = Renderer::Russian::PUBLISHER.key(publisher.to_s)
      { publisher: russian_publisher&.to_s || publisher }
    end

    # rule(year: simple(:year)) do
    #   { year: year.to_i }
    # end
    #
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
      # return russian_code.to_s if russian_code

      code = case code
             when "NWIP"
               "NP"
             when "D", "FPD"
               "DIS"
             when "FD", "F"
               "FDIS"
             when "Fpr"
               "PRF"
             when "pD", "PD"
               "CD"
             else
               code
             end
      Stage.new(abbr: (russian_code || code))
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
