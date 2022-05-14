module Pubid::Iso
  class Russian < Identifier
    PUBLISHER = { "ISO" => "ИСО", "IEC" => "МЭК" }.freeze
    STAGE = { "FDIS" => "ОПМС",
              "DIS" => "ПМС",
              "NP" => "НП",
              "AWI" => "АВИ",
              "CD" => "КПК",
              "PD" => "ПД",
              "FPD" => "ФПД",


    }.freeze
    TYPE = { "Guide" => "Руководство",
             "TS" => "ТС",
             "TR" => "ТО",
             "ISP" => "ИСП",
    }.freeze

    def identifier(with_date, with_language_code)
      if @type == "Guide"
        "Руководство #{originator}#{stage} #{number}#{part}#{iteration}"\
          "#{with_date && rendered_year || ''}#{edition}#{supplements}#{language(with_language_code)}"
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
