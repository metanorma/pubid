module Pubid::Iso
  class Transformer < Parslet::Transform
    rule(edition: "Ed") do
      { edition: "1" }
    end

    rule(stage: simple(:stage)) do |context|
      { stage: convert_stage(context[:stage]) }
    end

    rule(amendment_stage: simple(:amendment_stage)) do |context|
      { amendment_stage: convert_stage(context[:amendment_stage]) }
    end

    rule(corrigendum_stage: simple(:corrigendum_stage)) do |context|
      { corrigendum_stage: convert_stage(context[:corrigendum_stage]) }
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
      { type: case type
              when "GUIDE", "Руководство", "Руководства"
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
      { copublisher: case copublisher
                     when "CEI", "МЭК"
                       "IEC"
                     else
                       copublisher
                     end
      }
    end

    rule(publisher: simple(:publisher)) do
      { publisher: case publisher
                   when "ИСО"
                     "ISO"
                   else
                     publisher
                   end
      }
    end

    def self.convert_stage(code)
      case code
      when "D", "ПМС"
        "DIS"
      when "FD", "ОПМС"
        "FDIS"
      when "Fpr"
        "PRF"
      when "pD", "PD"
        "CD"
      else
        code
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
