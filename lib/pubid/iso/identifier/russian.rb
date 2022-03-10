module Pubid::Iso
  class Russian < Identifier
    PUBLISHER = { "ISO" => "ИСО", "IEC" => "МЭК" }.freeze
    STAGE = { "FDIS" => "ОПМС",
              "DIS" => "ПМС",
              "NP" => "НП",
              "AWI" => "АВИ",
              "CD" => "КПК",

    }.freeze
    TYPE = { "Guide" => "Руководство", "TS" => "ТС", "TR" => "ТО" }.freeze

    def identifier
      if @type == "Guide"
        "Руководство #{originator}#{stage} #{number}#{part}#{iteration}#{year}#{edition}#{supplements}#{language}"
      else
        super
      end
    end

    def publisher
      PUBLISHER[@publisher]
    end

    def copublisher
      super&.map { |copublisher| PUBLISHER[copublisher] }
    end

    def stage
      "#{(@copublisher && ' ') || '/'}#{STAGE[@stage]}" if @stage
    end
  end
end
