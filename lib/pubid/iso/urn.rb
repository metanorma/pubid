module Pubid::Iso
  class Urn < Identifier

    STAGES = { PWI: 0,
               NP: 10,
               AWI: 20,
               WD: 20.20,
               CD: 30,
               DIS: 40,
               FDIS: 50,
               PRF: 50,
               IS: 60 }.freeze

    def initialize(**opts)
      opts.each { |key, value| send("#{key}=", value) }
    end

    def to_s
      # docidentifier = originator [":" type] ":" docnumber [":" partnumber]
      # [[":" status] ":" edition]
      # [":" docversion] [":" language]

      if tctype
        "urn:iso:doc:#{originator}:#{tctype.downcase}:#{tcnumber}#{sctype}#{wgtype}:#{number}"
      else
        "urn:iso:std:#{originator}#{type}:#{number}#{part}#{stage}#{edition}#{supplement}#{language}"
      end
    end

    def tctype
      return @tctype.join(":") if @tctype.is_a?(Array)

      @tctype
    end

    def sctype
      return unless @sctype

      ":#{@sctype.downcase}:#{@scnumber}"
    end

    def wgtype
      return unless @wgtype

      if @wgnumber
        ":#{@wgtype.downcase}:#{@wgnumber}"
      else
        ":#{@wgtype.downcase}"
      end
    end

    def part
      ":-#{@part}" if @part
    end

    def render_stage(stage)
      return ":stage-#{sprintf('%05.2f', stage)}#{iteration}" if stage.is_a?(Float)

      ":stage-#{sprintf('%05.2f', STAGES[stage.to_sym])}#{iteration}"
    end

    def stage
      return render_stage(@urn_stage) if @urn_stage

      return render_stage(@stage) if @stage

      render_stage(@corrigendum_stage) if @corrigendum_stage
    end

    def originator
      # originator    = "iso" / "iso-iec" / "iso-cie" / "iso-astm" /
      #   "iso-ieee" / "iec"

      if @copublisher
        @copublisher = [@copublisher] unless @copublisher.is_a?(Array)
        @publisher.downcase + @copublisher.map(&:to_s).sort.map do |copublisher|
          "-#{copublisher.downcase.gsub('/', '-')}"
        end.join
      else
        @publisher.downcase
      end
    end

    def edition
      ":ed-#{@edition}" if @edition
    end

    def iteration
      ".v#{@iteration}" if @iteration
    end

    def type
      # type          = "data" / "guide" / "isp" / "iwa" /
      #   "pas" / "r" / "tr" / "ts" / "tta"
      if @type
        ":#{@type.downcase}"
      end
    end

    def supplement
      result = @amendments&.map(&:render_urn)&.join || ""

      result += @corrigendums&.map(&:render_urn)&.join || ""

      result
    end

    def language
      if @language
        ":#{@language}"
      end
    end
  end
end
