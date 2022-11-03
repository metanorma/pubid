module Pubid::Iso::Renderer
  class Russian < Base
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

    def render_typed_stage(typed_stage, opts, params)
      return nil if typed_stage.type == :guide

      return STAGE[typed_stage.to_s] if STAGE.key?(typed_stage.to_s)

      super
    end

    def render_identifier(params)
      if @params[:typed_stage]&.type == :guide
        "Руководство #{super(params)}"
      else
        super
      end
    end

    def render_publisher(publisher, _opts, _params)
      pub_string = super

      PUBLISHER.inject(pub_string) do |acc, (original, russian)|
        acc.gsub!(original, russian)
      end
    end

    def render_stage(stage, _opts, params)
      STAGE[stage.abbr] unless stage.nil?
    end

    def render_corrigendums(corrigendums, _opts, _params)
      super.gsub(" ", ".")
    end

    def render_amendments(amendments, _opts, _params)
      super.gsub(" ", ".")
    end
  end
end
