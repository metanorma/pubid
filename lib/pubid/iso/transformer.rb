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
        [Amendment.new(
          number: context[:amendments][:number],
          year: context[:amendments][:year],
          stage: context[:amendments][:stage] && convert_stage(context[:amendments][:stage]),
          iteration: context[:amendments][:iteration])]

      context
    end

    rule(corrigendums: subtree(:corrigendums)) do |context|
      context[:corrigendums] =
        [Corrigendum.new(
          number: context[:corrigendums][:number],
          year: context[:corrigendums][:year],
          stage: context[:corrigendums][:stage] && convert_stage(context[:corrigendums][:stage]),
          iteration: context[:corrigendums][:iteration])]

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
      { type: russian_type&.to_s ||
        case type
        # XXX: can't put 2 alternative Russian translations to dictionary, temporary hack
        when "GUIDE", "Руководства"
          "Guide"
        when "ТС"
          "TS"
        when "ТО"
          "TR"
        else
          type
        end
      }
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
